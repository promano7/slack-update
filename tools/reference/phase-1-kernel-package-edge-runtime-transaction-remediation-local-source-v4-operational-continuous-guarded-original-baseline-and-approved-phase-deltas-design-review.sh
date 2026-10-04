#!/bin/bash
set -euo pipefail
export LC_ALL=C
script_dir=$(CDPATH= cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)
repo_root=$(CDPATH= cd -- "$script_dir/../.." && pwd -P)
if [[ $# -eq 1 && $1 == --help ]]; then
    printf 'Usage: %s --output-dir DIR\nRepository-only continuous guarded original baseline and phase delta design review; no runtime authority.\n' "${0##*/}"
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

BASE = 'phase-1-kernel-package-edge-runtime-transaction-remediation-local-source-v4-operational-continuous-guarded-original-baseline-and-approved-phase-deltas-design-review'
PRIOR = 'phase-1-kernel-package-edge-runtime-transaction-remediation-local-source-v4-operational-expiry-revocation-and-bounded-recovery-design-review'
FIXTURE = 'tests/fixtures/reference/acceptance/phase-1'
OWN_HASHES = {'docs/reference/phase-1-kernel-package-edge-runtime-transaction-remediation-local-source-v4-operational-continuous-guarded-original-baseline-and-approved-phase-deltas-design-review.md': 'd3d2b97cacebd841cfd640d61fe6558d78653f28e9946381fcff23345693331c', 'tests/fixtures/reference/acceptance/phase-1/phase-1-kernel-package-edge-runtime-transaction-remediation-local-source-v4-operational-continuous-guarded-original-baseline-and-approved-phase-deltas-design-review-policy.json': '8c9f2601ab3658a2e693bdfcbd1b66f70727b748a11875b7c72d638ecc707c2e', 'tests/fixtures/reference/acceptance/phase-1/phase-1-kernel-package-edge-runtime-transaction-remediation-local-source-v4-operational-continuous-guarded-original-baseline-and-approved-phase-deltas-design-review-design.json': 'c26c93bf5f5dd596c8272cd1328a2f08f970053e6582fdccfbe278b904f20474', 'tests/fixtures/reference/acceptance/phase-1/phase-1-kernel-package-edge-runtime-transaction-remediation-local-source-v4-operational-continuous-guarded-original-baseline-and-approved-phase-deltas-design-review-checkpoint-confirmation.json': '2419ffcc8a8176d1b775a438efd993116ef3295438b1197e176694d1b910d404', 'tests/fixtures/reference/acceptance/phase-1/phase-1-kernel-package-edge-runtime-transaction-remediation-local-source-v4-operational-continuous-guarded-original-baseline-and-approved-phase-deltas-design-review-step323-user-acceptance.json': 'c5788e3e4f45a91960fcfabde9887b114422ba2c178b934bb7ffd421c9e8a7b5', 'tests/fixtures/reference/acceptance/phase-1/phase-1-kernel-package-edge-runtime-transaction-remediation-local-source-v4-operational-continuous-guarded-original-baseline-and-approved-phase-deltas-design-review-guard-resource-window-matrix.tsv': 'c3a1f3915a0530b21685e8cd49c2f6a33a58e19835b50d894ac56047967bc2bc', 'tests/fixtures/reference/acceptance/phase-1/phase-1-kernel-package-edge-runtime-transaction-remediation-local-source-v4-operational-continuous-guarded-original-baseline-and-approved-phase-deltas-design-review-original-phase-delta-matrix.tsv': 'd42b3fb3a1a97834bf03f218d9798b972905d7f71d0a123478b552bf42405212'}
CHANGELOG_PREFIX = '## Phase 1 step324 — continuous guards original baseline and approved phase deltas design review — 2026-10-04\n\n- Confirmed32332fbfba prefix, complete ordered271 PASS identical, first push success, clean tree and matching HEAD/origin. Full ID unknown. Preserve original22792-byte receipt and external confirmation without rewriting prepared323.318 remains last confirmed strong pause.\n- Preserve1494 accepted artifacts except additive CHANGELOG prefix; nine new artifacts. Full271 predecessor acceptance reruns with456/2251/843/547/717 and historical coverage exact. Bind320–323 designs and seven-domain313 writer map, frozen stages/source unchanged and v2 never sourced/run.\n- Explicit successor interstage barrier after stage1 traps and before stage2 owned writes: acquire stable outer exclusion, fresh validation and in-memory original production capture; stage3 exact backups verified against same original bytes/meta/presence before predecessor/config/package effects. Early stage0 preflight never guarded baseline.\n- Cover every overlapping actual writer/native protocol/alias/object/mount/content/dependency through full window; unknown nonparticipating writer rejects admission. Supervisor guard distinct from referenceFD9 and child-unlockable handles excluded. Owner loss cannot release while survivors mutate; unverifiable/lost/replaced guard stops effects with pending obligations, no force unlock/recreate/reacquire/rebind.\n- Compare complete snapshots to immutable original phase expectations: exact predecessor, reviewed local isolation/refresh, target-only apply, original restore. Preserve unrelated records/boot/GenInitrd/source/code/identity; never rebind baseline to predecessor or foreign drift. Raw pkglist SHA bound once, nested updates same raw bytes; restore original production state without changing owned audit pin and forbid further package consumers after restore.\n- Individual canonical owned-artifact whitelist only, no broad drift-hiding subtree exclusion.323 retained finite recovery rights plus valid continuous guard/exact backups/safe same identity/known child quiescence before restore, full original verification and target evidence before release. No target writes after release; independent publication controls through last receipt from closed captured data only.\n- Pure typed finite synthetic snapshot/guard/phase/failure models, no actual lock/writer/alias/source/archive/backup/package/child/restoration action. Six actual proofs, seven capabilities and ten cross obligations required-not-proven; actual live/host bindings null/unobserved. No delivery machine/controller cleanup introduced.324 application/tests/exact commit/user push pending, not strong pause;325 whole graph follows complete324 return. Production/Phase2 closed; Phase1/kernel edge incomplete;328 conditional repository design pause.\n\n'
BASELINE_JSON_SHA256 = 'dd097bcf58796c782eac9837dce77ae609b5af9d9c8ec5a0b68ef6ac0fbe7c10'
CONFIRMATION_SHA256 = '2419ffcc8a8176d1b775a438efd993116ef3295438b1197e176694d1b910d404'
RECEIPT_SHA256 = '715e66aabfe69c7e049d83ac4591791ae1e42ad5788e62185b31f812c5953bad'
TABLE_HASHES = ['c3a1f3915a0530b21685e8cd49c2f6a33a58e19835b50d894ac56047967bc2bc', 'd42b3fb3a1a97834bf03f218d9798b972905d7f71d0a123478b552bf42405212']

REQUIREMENTS_BASE = 'phase-1-kernel-package-edge-runtime-transaction-remediation-local-source-v4-operational-requirements-freeze-and-strong-safe-pause'
DESIGN_SPEC = {'schema': 1, 'step': 324, 'scope': 'continuous-guarded-original-baseline-and-approved-phase-deltas-design-only', 'design_version': 'guarded-original-phase-v1-review-not-operational-freeze', 'review_status': 'PASS-interstage-and-phase-contract-only-actual-implementation-and-conformance-blocked', 'selected_policy': 'stable-external-outer-exclusion-fresh-original-capture-and-immutable-approved-phase-expectations', 'previous_design_bindings': {'320': {'path': 'tests/fixtures/reference/acceptance/phase-1/phase-1-kernel-package-edge-runtime-transaction-remediation-local-source-v4-operational-admission-and-durable-consumption-design-review-design.json', 'sha256': '206070db792430966f1b1654d29d7fecabaf43288f1d208b1332d5a40432726f'}, '321': {'path': 'tests/fixtures/reference/acceptance/phase-1/phase-1-kernel-package-edge-runtime-transaction-remediation-local-source-v4-operational-admission-handoff-and-namespace-fd-design-review-design.json', 'sha256': 'c814396b3d002f3398b1d024ab30d9b74dfa6d84aee0c87df93215f571bd1540'}, '322': {'path': 'tests/fixtures/reference/acceptance/phase-1/phase-1-kernel-package-edge-runtime-transaction-remediation-local-source-v4-operational-stage7-owned-binding-effect-design-review-design.json', 'sha256': 'ff7428e2039927559130a6b0f58611a669f30215221aaf3887e3fa360438a494'}, '323': {'path': 'tests/fixtures/reference/acceptance/phase-1/phase-1-kernel-package-edge-runtime-transaction-remediation-local-source-v4-operational-expiry-revocation-and-bounded-recovery-design-review-design.json', 'sha256': '40a574a020fcd8a5a6e79d0faebea6e00e62283751a94bcd877a9b47182d8b98'}}, 'writer_resource_map_binding': {'path': 'tests/fixtures/reference/acceptance/phase-1/phase-1-kernel-package-edge-runtime-transaction-remediation-local-source-v4-operational-platform-writer-serialization-requirements-review-writer-resource-map.tsv', 'sha256': '9f3b0fe638ca801fec47dd8bcf36c3caf92c016da61e3d1706e06a665765b39c', 'domain_count': 7}, 'resource_domains': ['package-database', 'Slackpkg-state', 'configuration-and-mirrors', 'boot-and-GenInitrd', 'source-and-archives', 'backend-and-dependencies', 'transaction-owned-state'], 'interstage_contract': {'history': 'frozen0/1/2/3-stages-not-rewritten; explicit-successor-integration-barrier-between1-and2', 'order': 'stage0-readonly-memory-preflight-then-stage1-traps-then-acquire-outer-guard-and-fresh-revalidate-capture-original-in-memory-before-stage2-owned-writes', 'stage3': 'persist-and-verify-exact-original-backups-from-guarded-capture-content-metadata-and-presence-before-predecessor-config-package-writes', 'authority': 'same-original-consumed-active-attempt-and323-live-split-rights; no-unused-grant-per-call'}, 'guard_contract': {'actual_guard_object': None, 'actual_native_protocol': None, 'actual_writer_inventory': None, 'coverage': 'all-seven-requirement-domains-and-every-overlapping-direct-manual-scheduled-helper-privileged-writer-through-entire-mutation-window', 'admission': 'reviewed-common-compatible-protocol-or-proven-controlled-entrypoint-prevention; unknown-or-nonparticipating-writer-blocks-admission', 'handle': 'stable-supervisor-owned-distinct-from-reference-FD9-not-child-inherited-unlockable; actual-object-API-range-mount-open-description-lifetime-proof-required', 'continuity': 'before-and-through-every-owned-target-config-package-nested-refresh-helper-consumption-recovery-and-target-evidence-effect', 'failure': 'loss-contention-object-replacement-unverifiable-owner-or-writer-state-latches-stop-and-pending; no-force-unlock-unlink-recreate-reacquire-or-rebind', 'owner_loss': 'parent-exit-not-child-quiescence; exclusion-must-survive-or-independently-prevent-all-surviving-writes-otherwise-unknown-pending', 'release': 'known-owned-child-quiescence-exact-original-restoration-full-invariants-and-target-evidence-before-release; no-target-writes-afterward'}, 'baseline_contract': {'actual_baseline': None, 'actual_backup_bindings': None, 'identity': 'single-original-production-baseline-under-continuous-guard-content-owner-mode-type-presence-absence-and-canonical-alias-objects-not-early-preflight-or-self-rebound-current-state', 'scope': 'exact-target-config-state-boot-GenInitrd-unrelated-package-source-archive-code-dependency-and-identity-invariants', 'owned_artifacts': 'only-individually-recorded-whitelisted-transaction-owned-work-backup-binding-evidence-effects-separated; no-broad-subtree-exclusion-to-hide-target-drift', 'expected': 'original-to-reviewed-predecessor-to-local-isolation-and-fresh-pkglist-to-exact-target-to-original; preserve-original-inputs-through-all-approved-deltas'}, 'pkglist_contract': {'actual_raw_pin': None, 'binding': 'fresh-regular-nonempty-refresh-exit0-both-stream-guards-then-bind-raw-SHA-once-for-stage7-and-all-nested-consumers', 'replacement': 'logical-row-equivalence-not-same-raw-bytes; only-explicitly-reviewed-regular-object-replacement-with-identical-bound-raw-SHA-and-independent-identity-writer-proof', 'restoration': 'restore-original-production-state-and-pkglist-under-original-backups-without-changing-owned-audit-pin; no-further-package-consumer-after-restore'}, 'recovery_contract': {'policy': 'exact323-retained-finite-same-attempt-rights-fence-deadline-budget-and-safe-identity-not-blanket-exemption', 'order': 'persistent-forward-stop-known-owned-child-drain-verified-original-backup-restore-full-invariants-target-evidence-then-release', 'unknown': 'partial-package-config-binding-guard-or-child-outcome-never-auto-close-retry-rehash-rebind-or-restore-foreign-drift; retain-original-status-backups-and-pending-obligations'}, 'publication_contract': 'target-guard-closure-does-not-prove-recipient-content-writer-exclusion; separate316/325-controls-through-last-receipt-use-captured-closed-data-only', 'successor_sequence': ['arm-traps', 'acquire-outer-guard', 'fresh-original-capture', 'initialize-owned-workspace', 'verify-original-backups', 'stage-exact-predecessor', 'isolate-local-config', 'refresh-new-pkglist', 'pin-raw-pkglist', 'commit-owned-binding', 'target-only-apply', 'drain-owned-children', 'restore-original', 'verify-original', 'close-target-evidence', 'release-target-control'], 'prerequisite_gates': ['same_consumed_authenticated_attempt', 'reviewed_external_forward_recovery_fence', 'complete_platform_writers_and_native_protocol', 'independent_stable_outer_guard_identity', 'owner_failure_child_containment', 'checked_source_archive_backend_dependencies', 'canonical_alias_parent_owner_objects', 'same_safe_boot_target_identity', 'reviewed_original_backup_roles', 'namespace_FD_no_fallback'], 'requirements': {'traps_before_guarded_owned_writes': True, 'guard_before_fresh_original_capture': True, 'early_preflight_not_baseline': True, 'exact_original_backup_content_metadata_presence': True, 'all_seven_resource_writer_domains': True, 'unknown_writer_blocks_admission': True, 'stable_supervisor_guard_not_referenceFD9': True, 'no_child_unlock_or_surviving_unexcluded_writer': True, 'approved_phase_deltas_not_initialDB_equality': True, 'unrelated_boot_source_backend_invariants_preserved': True, 'no_self_rebind_original_or_raw_pkglist': True, 'raw_pin_once_nested_calls_samebytes': True, 'original_production_restore_does_not_change_audit_pin': True, 'bounded_safe_same_attempt_recovery_only': True, 'quiescence_before_restore_and_release': True, 'complete_target_evidence_under_guard': True, 'no_target_writes_after_release': True, 'owned_artifacts_individual_whitelist_only': True, 'frozen_history_unchanged': True, 'publication_rights_separate': True}, 'proof_state': {'selected_guarded_original_contract': True, 'actual_guard_acquired': False, 'actual_writer_exclusion_proven': False, 'actual_native_protocol_proven': False, 'actual_guard_failure_containment_proven': False, 'actual_original_baseline_captured': False, 'actual_backups_verified': False, 'actual_phase_deltas_proven': False, 'actual_raw_pin_bound': False, 'actual_children_drained': False, 'actual_restoration_verified': False, 'actual_guard_released': False, 'actual_live_bindings': None, 'actual_host_obligations_observed': None, 'actual_host_obligations_claimed_absent': False, 'actual_host_obligations_closed': False, 'actual_grant_consumed': False, 'historical_v2_sourced_or_run': False, 'operational_implementation_complete': False, 'operational_conformance': False, 'operational_readiness': False}, 'future_proof_obligations': [{'id': 'platform-writers-and-guard-identity', 'evidence': 'Actual complete15.0/current writer/native lock/controlled entrypoint inventory, canonical DB aliases/mounts/objects/API/lifetime and every source/backend/dependency/content writer, not advisory lock name or process scan.', 'status': 'required-not-proven'}, {'id': 'interstage-fresh-original-baseline', 'evidence': 'Actual traps-first explicit successor barrier between stages1/2 acquires stable exclusion and fresh original state before owned writes; stage3 verified backups match captured content/meta/presence without reusing stage0 preflight or reordering frozen history.', 'status': 'required-not-proven'}, {'id': 'approved-phase-delta-equivalence', 'evidence': 'Actual exact predecessor/target/original archive roles and permitted package/header/config/mirrors/state changes, invariant unrelated records/boot/GenInitrd/source/code/identity through whole helper graph; no observed-state self-rebind.', 'status': 'required-not-proven'}, {'id': 'raw-pkglist-pin-and-restored-production-role', 'evidence': 'Actual raw SHA bound once after fresh regular refresh, all nested updates preserve it; approved same-byte regular replacement requires identity/writer proof; restoring original production state does not change audit pin or permit more package consumers.', 'status': 'required-not-proven'}, {'id': 'owner-child-failure-and-safe-recovery', 'evidence': 'Actual distinct non-child-unlockable supervisor guard survives failure or prevents all surviving writes; known owned children drain before bounded323 authorized same-identity original restore, unknown/lost guard stays pending without forced release/reacquire.', 'status': 'required-not-proven'}, {'id': 'target-evidence-closure-and-publication-separation', 'evidence': 'Actual restoration/full invariant verification/target evidence under continuous guard before release; only reviewed owned evidence/backups remain, no broad exclusion hiding drift; separate publication controls and last receipt from closed data.', 'status': 'required-not-proven'}], 'seven_requirements_bindings': [{'capability': 'real-reference-integration-and-selector-equivalence', 'operational_conformance': False, 'policy_path': 'tests/fixtures/reference/acceptance/phase-1/phase-1-kernel-package-edge-runtime-transaction-remediation-local-source-v4-operational-reference-integration-and-selector-requirements-review-policy.json', 'policy_sha256': '9fcb69804f2d3abff675044f477b903416314bb7a195a938e45b1ee1f1260fa1', 'requirements_status': 'reviewed-not-operationally-complete', 'review_path': 'tests/fixtures/reference/acceptance/phase-1/phase-1-kernel-package-edge-runtime-transaction-remediation-local-source-v4-operational-reference-integration-and-selector-requirements-review-review.json', 'review_sha256': '69d846f1a5473cc8e2859ee7f3a242047c32d49e364601f9429054a742cdabf8', 'step': 310}, {'capability': 'namespace-command-transport-and-no-fallback', 'operational_conformance': False, 'policy_path': 'tests/fixtures/reference/acceptance/phase-1/phase-1-kernel-package-edge-runtime-transaction-remediation-local-source-v4-operational-namespace-transport-and-no-fallback-requirements-review-policy.json', 'policy_sha256': '3f321ef0ca8317cb6261d707dc158ae306ef92435430e824d77e42b9e066b8a8', 'requirements_status': 'reviewed-not-operationally-complete', 'review_path': 'tests/fixtures/reference/acceptance/phase-1/phase-1-kernel-package-edge-runtime-transaction-remediation-local-source-v4-operational-namespace-transport-and-no-fallback-requirements-review-review.json', 'review_sha256': 'ed2b6651ab1f54eaea7cd33c765f9d677a0cb257d47840237babd966281b9af9', 'step': 311}, {'capability': 'absolute-backend-path-and-SHA', 'operational_conformance': False, 'policy_path': 'tests/fixtures/reference/acceptance/phase-1/phase-1-kernel-package-edge-runtime-transaction-remediation-local-source-v4-operational-absolute-backend-identity-requirements-review-policy.json', 'policy_sha256': '8e64828bd8abfb55f36e326177c8ddb24bb0e81a3f20bf592b949f9e1a0fc80a', 'requirements_status': 'reviewed-not-operationally-complete', 'review_path': 'tests/fixtures/reference/acceptance/phase-1/phase-1-kernel-package-edge-runtime-transaction-remediation-local-source-v4-operational-absolute-backend-identity-requirements-review-review.json', 'review_sha256': 'b23906d94ad0111daf310cf563ad056020ec4066e14b341bec7bf6e0ae28dd26', 'step': 312}, {'capability': 'reviewed-platform-writer-serialization', 'operational_conformance': False, 'policy_path': 'tests/fixtures/reference/acceptance/phase-1/phase-1-kernel-package-edge-runtime-transaction-remediation-local-source-v4-operational-platform-writer-serialization-requirements-review-policy.json', 'policy_sha256': '4f387f3b9fb6c90f8b018b45fa0e3529786c5908d6a3027a2113a7a9f25d47e8', 'requirements_status': 'reviewed-not-operationally-complete', 'review_path': 'tests/fixtures/reference/acceptance/phase-1/phase-1-kernel-package-edge-runtime-transaction-remediation-local-source-v4-operational-platform-writer-serialization-requirements-review-review.json', 'review_sha256': 'ba896b35f91d1adc6692a6813652752b158eb258af3267c85e80ec024fe856f4', 'step': 313}, {'capability': 'fresh-single-use-grant-source-target-predecessor-and-boot', 'operational_conformance': False, 'policy_path': 'tests/fixtures/reference/acceptance/phase-1/phase-1-kernel-package-edge-runtime-transaction-remediation-local-source-v4-operational-fresh-single-use-grant-requirements-review-policy.json', 'policy_sha256': '3e9bdf7b20fef359781964c489aeee00749fc9039b8397c72eeb2c95c8e9a64f', 'requirements_status': 'reviewed-not-operationally-complete', 'review_path': 'tests/fixtures/reference/acceptance/phase-1/phase-1-kernel-package-edge-runtime-transaction-remediation-local-source-v4-operational-fresh-single-use-grant-requirements-review-review.json', 'review_sha256': '73c7905dede694806bf8062ff0063775f8f927e7dada91a0bf339e87061affb6', 'step': 314}, {'capability': 'real-source-and-archive-revalidation', 'operational_conformance': False, 'policy_path': 'tests/fixtures/reference/acceptance/phase-1/phase-1-kernel-package-edge-runtime-transaction-remediation-local-source-v4-operational-real-source-and-archive-revalidation-requirements-review-policy.json', 'policy_sha256': 'b8fbffd1dff20736ad71850677aa613aa557c792b42c8616f9d8fe3073c0efe2', 'requirements_status': 'reviewed-not-operationally-complete', 'review_path': 'tests/fixtures/reference/acceptance/phase-1/phase-1-kernel-package-edge-runtime-transaction-remediation-local-source-v4-operational-real-source-and-archive-revalidation-requirements-review-review.json', 'review_sha256': '36a7f9559aaa87550ed7f4b2544960df4ec71775cb3444fd6070279e4613f5f0', 'step': 315}, {'capability': 'operational-owner-and-publication-path-bindings', 'operational_conformance': False, 'policy_path': 'tests/fixtures/reference/acceptance/phase-1/phase-1-kernel-package-edge-runtime-transaction-remediation-local-source-v4-operational-owner-and-publication-path-requirements-review-policy.json', 'policy_sha256': 'b816d61589c59fefa1c35df234269c05f1698eddab6c615a99ae030356729377', 'requirements_status': 'reviewed-not-operationally-complete', 'review_path': 'tests/fixtures/reference/acceptance/phase-1/phase-1-kernel-package-edge-runtime-transaction-remediation-local-source-v4-operational-owner-and-publication-path-requirements-review-review.json', 'review_sha256': '30c9472c9b68fd6073783c678600c9c5f41730a43a6525b132c2a0d725213ecf', 'step': 316}], 'preserved_cross_obligations': [{'id': 'claim-traps-containment', 'negative_case': 'promote-review-or-private-fixture-to-resolved-claim-traps-containment', 'required_evidence': 'No local ledger before traps; no unreviewed admission socket/service inherited by isolated backend; no protocol chosen', 'scope': 'future-operational-conformance-not-executed', 'status': 'required-not-proven'}, {'id': 'guarded-baseline', 'negative_case': 'promote-review-or-private-fixture-to-resolved-guarded-baseline', 'required_evidence': 'Keep frozen stages unchanged; interstage integration and real baseline proof still required', 'scope': 'future-operational-conformance-not-executed', 'status': 'required-not-proven'}, {'id': 'binding-effect-classification', 'negative_case': 'promote-review-or-private-fixture-to-resolved-binding-effect-classification', 'required_evidence': 'Explicit owned binding effect classification and traps/guard/grant integration review before operational freeze; do not rewrite frozen bytes', 'scope': 'future-operational-conformance-not-executed', 'status': 'required-not-proven'}, {'id': 'whole-effect-graph', 'negative_case': 'promote-review-or-private-fixture-to-resolved-whole-effect-graph', 'required_evidence': 'Persistent forward failure latch and complete actual helpers/selectors/namespace FD/identity/writer graph; no fallback', 'scope': 'future-operational-conformance-not-executed', 'status': 'required-not-proven'}, {'id': 'retained-bytes-and-writers', 'negative_case': 'promote-review-or-private-fixture-to-resolved-retained-bytes-and-writers', 'required_evidence': 'Actual ancestry aliases and content/dependency writer exclusion continuously through checked-byte consumption; no self-rehash/rebind', 'scope': 'future-operational-conformance-not-executed', 'status': 'required-not-proven'}, {'id': 'same-attempt-phase-deltas', 'negative_case': 'promote-review-or-private-fixture-to-resolved-same-attempt-phase-deltas', 'required_evidence': 'Never demand unused grant per nested call or rebind baseline to foreign drift; independently verified archive roles and same-boot scope', 'scope': 'future-operational-conformance-not-executed', 'status': 'required-not-proven'}, {'id': 'pkglist-selector-status', 'negative_case': 'promote-review-or-private-fixture-to-resolved-pkglist-selector-status', 'required_evidence': 'SHA bound once; zero install-new one upgrade required; raw helper0/20 differs from frozen emulator and real mandatory upgrade20 fails', 'scope': 'future-operational-conformance-not-executed', 'status': 'required-not-proven'}, {'id': 'target-publication-controls', 'negative_case': 'promote-review-or-private-fixture-to-resolved-target-publication-controls', 'required_evidence': 'Drain children verify restore close target evidence then release; captured closed data only; separate publication controls through receipt/handoff', 'scope': 'future-operational-conformance-not-executed', 'status': 'required-not-proven'}, {'id': 'last-receipt-durability', 'negative_case': 'promote-review-or-private-fixture-to-resolved-last-receipt-durability', 'required_evidence': 'Actual supported no-replace file/meta/directory/storage semantics and trusted origin; no pair atomicity self-containing receipt or SHA authority', 'scope': 'future-operational-conformance-not-executed', 'status': 'required-not-proven'}, {'id': 'failure-recovery-rights', 'negative_case': 'promote-review-or-private-fixture-to-resolved-failure-recovery-rights', 'required_evidence': 'No blanket exemption renewal replay retry or wrong-boot restore; preserve unknown/pending obligations and backups for separately authorized recovery', 'scope': 'future-operational-conformance-not-executed', 'status': 'required-not-proven'}], 'remaining_operational_blockers': ['314-durable-claim-traps-gap-retained', 'admission-service-no-broker-FD-isolation-integration-unresolved', 'stage7-readonly-versus-owned-binding-effect-classification-unresolved', 'all-seven-capabilities-still-require-operational-implementation-and-conformance', 'actual-recovery-expiry-revocation-policy-unselected', 'actual-current-machine-and-controller-obligations-unobserved'], 'remaining_design_reviews': [325, 326, 327, 328], 'compatibility_scope': ['Slackware-15.0', 'Slackware-current'], 'private_model_scope': 'complete-synthetic-before-after-phase-vectors-and-finite-guard-owner-failure-model-not-live-inventory-lock-state-backup-or-restoration-proof', 'unresolved_design_edges': ['325-whole-service-fence-helper-selector-source-backend-publication-effect-graph', '326-complete-failure-model-and-independent-platform-conformance-plan', 'actual-writer-native-lock-alias-guard-baseline-backup-delta-child-restoration-and-closure-proofs-unimplemented']}
SUFFIXES = ['-policy.json', '-design.json', '-checkpoint-confirmation.json', '-step323-user-acceptance.json', '-guard-resource-window-matrix.tsv', '-original-phase-delta-matrix.tsv']

PRIOR_DESIGN_SHA256 = '40a574a020fcd8a5a6e79d0faebea6e00e62283751a94bcd877a9b47182d8b98'
GATE_KEYS = ['same_consumed_authenticated_attempt', 'reviewed_external_forward_recovery_fence', 'complete_platform_writers_and_native_protocol', 'independent_stable_outer_guard_identity', 'owner_failure_child_containment', 'checked_source_archive_backend_dependencies', 'canonical_alias_parent_owner_objects', 'same_safe_boot_target_identity', 'reviewed_original_backup_roles', 'namespace_FD_no_fallback']


MODEL_ACTIONS = ['early-preflight', 'arm-traps', 'acquire-outer-guard', 'fresh-original-capture', 'initialize-owned-workspace', 'verify-original-backups', 'stage-exact-predecessor', 'isolate-local-config', 'refresh-new-pkglist', 'pin-raw-pkglist', 'commit-owned-binding', 'target-only-apply', 'drain-owned-children', 'restore-original', 'verify-original', 'close-target-evidence', 'release-target-control', 'nested-update', 'fail-forward', 'supervisor-loss', 'rebind-original', 'rebind-pkglist', 'force-unlock', 'reacquire', 'publication', 'target-write-after-release']
RECOVERY_ACTIONS = ['drain-owned-children', 'restore-original', 'verify-original', 'close-target-evidence', 'release-target-control']

PHASE_SEQUENCE = ['arm-traps', 'acquire-outer-guard', 'fresh-original-capture', 'initialize-owned-workspace', 'verify-original-backups', 'stage-exact-predecessor', 'isolate-local-config', 'refresh-new-pkglist', 'pin-raw-pkglist', 'commit-owned-binding', 'target-only-apply', 'drain-owned-children', 'restore-original', 'verify-original', 'close-target-evidence', 'release-target-control']
RECOVERY_SEQUENCE = ['drain-owned-children', 'restore-original', 'verify-original', 'close-target-evidence', 'release-target-control']
FIXTURE_ORIGINAL = {'package_header': 'fixture-original-header', 'package_unrelated': 'fixture-original-unrelated-records', 'header_file_bytes': 'fixture-original-header-files', 'header_file_mode_owner': 'fixture-original-header-metadata', 'configuration_bytes_mode_owner': 'fixture-original-config', 'mirrors_bytes_mode_owner': 'fixture-original-mirrors', 'slackpkg_state_bytes_mode_owner': 'fixture-original-production-state', 'pkglist_raw': 'fixture-original-production-pkglist', 'boot_GenInitrd_bytes_metadata': 'fixture-original-boot-GenInitrd', 'source_manifest': 'fixture-original-local-source', 'target_archive': 'fixture-exact-target-role', 'predecessor_archive': 'fixture-exact-predecessor-role', 'baseline_archive': 'fixture-exact-original-baseline-role', 'backend_dependencies': 'fixture-checked-original-code-dependencies', 'DB_alias_object': 'fixture-canonical-same-package-DB', 'boot_target_identity': 'fixture-original-same-boot-target'}
FIXTURE_PHASES = {'original': {'package_header': 'fixture-original-header', 'package_unrelated': 'fixture-original-unrelated-records', 'header_file_bytes': 'fixture-original-header-files', 'header_file_mode_owner': 'fixture-original-header-metadata', 'configuration_bytes_mode_owner': 'fixture-original-config', 'mirrors_bytes_mode_owner': 'fixture-original-mirrors', 'slackpkg_state_bytes_mode_owner': 'fixture-original-production-state', 'pkglist_raw': 'fixture-original-production-pkglist', 'boot_GenInitrd_bytes_metadata': 'fixture-original-boot-GenInitrd', 'source_manifest': 'fixture-original-local-source', 'target_archive': 'fixture-exact-target-role', 'predecessor_archive': 'fixture-exact-predecessor-role', 'baseline_archive': 'fixture-exact-original-baseline-role', 'backend_dependencies': 'fixture-checked-original-code-dependencies', 'DB_alias_object': 'fixture-canonical-same-package-DB', 'boot_target_identity': 'fixture-original-same-boot-target'}, 'predecessor': {'package_header': 'fixture-exact-predecessor-header', 'package_unrelated': 'fixture-original-unrelated-records', 'header_file_bytes': 'fixture-exact-predecessor-files', 'header_file_mode_owner': 'fixture-reviewed-predecessor-metadata', 'configuration_bytes_mode_owner': 'fixture-original-config', 'mirrors_bytes_mode_owner': 'fixture-original-mirrors', 'slackpkg_state_bytes_mode_owner': 'fixture-original-production-state', 'pkglist_raw': 'fixture-original-production-pkglist', 'boot_GenInitrd_bytes_metadata': 'fixture-original-boot-GenInitrd', 'source_manifest': 'fixture-original-local-source', 'target_archive': 'fixture-exact-target-role', 'predecessor_archive': 'fixture-exact-predecessor-role', 'baseline_archive': 'fixture-exact-original-baseline-role', 'backend_dependencies': 'fixture-checked-original-code-dependencies', 'DB_alias_object': 'fixture-canonical-same-package-DB', 'boot_target_identity': 'fixture-original-same-boot-target'}, 'isolated': {'package_header': 'fixture-exact-predecessor-header', 'package_unrelated': 'fixture-original-unrelated-records', 'header_file_bytes': 'fixture-exact-predecessor-files', 'header_file_mode_owner': 'fixture-reviewed-predecessor-metadata', 'configuration_bytes_mode_owner': 'fixture-reviewed-isolated-local-config', 'mirrors_bytes_mode_owner': 'fixture-reviewed-local-only-mirrors', 'slackpkg_state_bytes_mode_owner': 'fixture-reviewed-isolated-state', 'pkglist_raw': 'fixture-original-production-pkglist', 'boot_GenInitrd_bytes_metadata': 'fixture-original-boot-GenInitrd', 'source_manifest': 'fixture-original-local-source', 'target_archive': 'fixture-exact-target-role', 'predecessor_archive': 'fixture-exact-predecessor-role', 'baseline_archive': 'fixture-exact-original-baseline-role', 'backend_dependencies': 'fixture-checked-original-code-dependencies', 'DB_alias_object': 'fixture-canonical-same-package-DB', 'boot_target_identity': 'fixture-original-same-boot-target'}, 'refreshed': {'package_header': 'fixture-exact-predecessor-header', 'package_unrelated': 'fixture-original-unrelated-records', 'header_file_bytes': 'fixture-exact-predecessor-files', 'header_file_mode_owner': 'fixture-reviewed-predecessor-metadata', 'configuration_bytes_mode_owner': 'fixture-reviewed-isolated-local-config', 'mirrors_bytes_mode_owner': 'fixture-reviewed-local-only-mirrors', 'slackpkg_state_bytes_mode_owner': 'fixture-reviewed-isolated-state', 'pkglist_raw': 'fixture-one-fresh-exact-raw-pkglist', 'boot_GenInitrd_bytes_metadata': 'fixture-original-boot-GenInitrd', 'source_manifest': 'fixture-original-local-source', 'target_archive': 'fixture-exact-target-role', 'predecessor_archive': 'fixture-exact-predecessor-role', 'baseline_archive': 'fixture-exact-original-baseline-role', 'backend_dependencies': 'fixture-checked-original-code-dependencies', 'DB_alias_object': 'fixture-canonical-same-package-DB', 'boot_target_identity': 'fixture-original-same-boot-target'}, 'target': {'package_header': 'fixture-exact-target-header', 'package_unrelated': 'fixture-original-unrelated-records', 'header_file_bytes': 'fixture-exact-target-files', 'header_file_mode_owner': 'fixture-reviewed-target-metadata', 'configuration_bytes_mode_owner': 'fixture-reviewed-isolated-local-config', 'mirrors_bytes_mode_owner': 'fixture-reviewed-local-only-mirrors', 'slackpkg_state_bytes_mode_owner': 'fixture-reviewed-isolated-state', 'pkglist_raw': 'fixture-one-fresh-exact-raw-pkglist', 'boot_GenInitrd_bytes_metadata': 'fixture-original-boot-GenInitrd', 'source_manifest': 'fixture-original-local-source', 'target_archive': 'fixture-exact-target-role', 'predecessor_archive': 'fixture-exact-predecessor-role', 'baseline_archive': 'fixture-exact-original-baseline-role', 'backend_dependencies': 'fixture-checked-original-code-dependencies', 'DB_alias_object': 'fixture-canonical-same-package-DB', 'boot_target_identity': 'fixture-original-same-boot-target'}}
FIXTURE_RAW_PIN = '72856bbe09255dc7f5ab77df8a6b13288a185c4d4c4f35315421df5d6df6a71e'

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
    exact(sha((json.dumps(c,ensure_ascii=False,sort_keys=True,indent=2)+'\n').encode()),CONFIRMATION_SHA256,'external323 confirmation')
    exact(sorted(receipt),['encoding','original_display_sha256','original_display_size_bytes','text'],'receipt fields')
    exact(receipt['encoding'],'utf8-json-text','receipt encoding');raw=receipt['text'].encode()
    exact(sha(raw),RECEIPT_SHA256,'original323 digest');exact(len(raw),22792,'original323 length')
    exact(receipt['original_display_sha256'],RECEIPT_SHA256,'receipt digest metadata');exact(receipt['original_display_size_bytes'],22792,'receipt size metadata')
    lines=receipt['text'].splitlines();exact(sum(x.startswith('PASS: ') for x in lines),271,'complete271 return')
    exact(lines.count('Result: PASS (271 passes, 0 failures)'),1,'full271 summary')
    log='32fbfba (HEAD -> main, origin/main, origin/HEAD) Phase 1 step 323: review expiry revocation and bounded same-attempt recovery'
    exact(lines.count(log),2,'matching323 HEAD origin')
    if '[main 32fbfba]' not in receipt['text'] or 'dfee48f..32fbfba  main -> main' not in receipt['text']:raise ValueError('missing323 commit/push')
    return True

def verify_history(root, policy):
    binding = policy['baseline_sha256_bindings']
    serialized = (json.dumps(binding, ensure_ascii=False, sort_keys=True, indent=2)+'\n').encode()
    exact(sha(serialized),BASELINE_JSON_SHA256,'exact accepted1494 manifest')
    exact(len(binding),1494,'accepted1494 file count')
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
    exact(design,DESIGN_SPEC,'exact continuous guard original baseline contract')
    exact(sha((json.dumps(prior,ensure_ascii=False,sort_keys=True,indent=2)+'\n').encode()),PRIOR_DESIGN_SHA256,'exact323 recovery contract')
    for step,binding in design['previous_design_bindings'].items():exact(sha(history[binding['path']]),binding['sha256'],'exact prior design '+step)
    exact(design['seven_requirements_bindings'],frozen['seven_review_bindings'],'seven frozen requirements')
    exact(design['preserved_cross_obligations'],frozen['proof_obligations'],'ten frozen cross obligations')
    exact(sha(history[design['writer_resource_map_binding']['path']]),design['writer_resource_map_binding']['sha256'],'exact seven domain writer requirements')
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


def simulate_private_guarded_phases(value):
    exact(sorted(value),['conditions','events','origin','scope'],'guard model fields')
    exact(value['origin'],'synthetic-private-fixture','guard origin');exact(value['scope'],'continuous-guard-original-phase-contract-only','guard scope')
    exact(sorted(value['conditions']),sorted(GATE_KEYS),'guard prerequisites')
    if any(type(x) is not bool for x in value['conditions'].values()):raise ValueError('typed guard prerequisite')
    if type(value['events']) is not list or len(value['events'])>32:raise ValueError('bounded phase schedule')
    gates=all(value['conditions'].values());progress=0;recovery_cursor=0;latched=not gates;uncertain=False;guard=False;traps=False;captured=False;backups=False
    state=dict(FIXTURE_ORIGINAL);original=None;pin=None;owned=False;binding=False;drained=False;restored=False;verified=False;evidence=False;released=False;status=None;denied=0;trace=[]
    for event in value['events']:
        exact(sorted(event),['action','after','before','guard_continuous','identity_safe','recovery_rights_valid','writers_excluded'],'phase event fields')
        action=event['action']
        if type(action) is not str or action not in MODEL_ACTIONS:raise ValueError('typed phase action')
        for key in ['guard_continuous','identity_safe','recovery_rights_valid','writers_excluded']:
            if type(event[key]) is not bool:raise ValueError('typed phase event condition')
        for key in ['before','after']:
            if type(event[key]) is not dict or sorted(event[key])!=sorted(FIXTURE_ORIGINAL) or any(type(x) is not str for x in event[key].values()):raise ValueError('complete typed synthetic snapshot')
        allowed=False;target_write=False;owned_write=False;proposed=dict(state)
        if action=='early-preflight':
            # Early memory data never becomes the guarded original capture.
            allowed=progress==0 and not latched
        elif action in ['fail-forward','supervisor-loss']:
            latched=True;allowed=True
            if status is None:status='original-forward-failure' if action=='fail-forward' else 'owner-loss-unknown'
            if action=='supervisor-loss':uncertain=True;guard=False
        else:
            safe=gates and not uncertain and not released and event['identity_safe'] and event['writers_excluded'] and event['guard_continuous']
            # No resetting state from caller observations; compare against immutable phase expectations.
            if event['before']!=state:
                safe=False;uncertain=True
            if progress<len(PHASE_SEQUENCE) and action==PHASE_SEQUENCE[progress] and not latched:
                allowed=safe
                if progress>=2:allowed=allowed and traps and guard
            elif latched and action in RECOVERY_SEQUENCE:
                allowed=safe and guard and traps and captured and backups and event['recovery_rights_valid'] and recovery_cursor<len(RECOVERY_SEQUENCE) and action==RECOVERY_SEQUENCE[recovery_cursor]
            if action in RECOVERY_SEQUENCE:
                allowed=allowed and event['recovery_rights_valid']
            if allowed:
                if action=='arm-traps':traps=True
                elif action=='acquire-outer-guard':guard=True
                elif action=='fresh-original-capture':original=dict(state);captured=True
                elif action=='initialize-owned-workspace':allowed=captured;owned_write=True
                elif action=='verify-original-backups':allowed=captured and owned;owned_write=True
                elif action=='stage-exact-predecessor':allowed=backups;proposed=dict(FIXTURE_PHASES['predecessor']);target_write=True
                elif action=='isolate-local-config':proposed=dict(FIXTURE_PHASES['isolated']);target_write=True
                elif action=='refresh-new-pkglist':proposed=dict(FIXTURE_PHASES['refreshed']);target_write=True
                elif action=='pin-raw-pkglist':allowed=pin is None
                elif action=='commit-owned-binding':allowed=pin==FIXTURE_RAW_PIN and owned;owned_write=True
                elif action=='target-only-apply':allowed=binding and pin==FIXTURE_RAW_PIN;proposed=dict(FIXTURE_PHASES['target']);target_write=True
                elif action=='drain-owned-children':pass
                elif action=='restore-original':allowed=drained and backups and original is not None;proposed=dict(original);target_write=state!=proposed
                elif action=='verify-original':allowed=drained and restored and state==original
                elif action=='close-target-evidence':allowed=drained and verified and state==original;owned_write=True
                elif action=='release-target-control':allowed=drained and verified and evidence and state==original
            elif action=='nested-update' and not latched:
                allowed=safe and guard and binding and pin==FIXTURE_RAW_PIN and state in [FIXTURE_PHASES['refreshed'],FIXTURE_PHASES['target']] and not drained
                target_write=True
            if allowed and event['after']!=proposed:
                allowed=False;uncertain=True
            if allowed:
                state=proposed
                if action=='initialize-owned-workspace':owned=True
                elif action=='verify-original-backups':backups=True
                elif action=='pin-raw-pkglist':pin=FIXTURE_RAW_PIN
                elif action=='commit-owned-binding':binding=True
                elif action=='drain-owned-children':
                    drained=True;latched=True
                    if status is None:status='forward-complete'
                elif action=='restore-original':restored=True
                elif action=='verify-original':verified=True
                elif action=='close-target-evidence':evidence=True
                elif action=='release-target-control':released=True;guard=False
                if action in RECOVERY_SEQUENCE:
                    recovery_cursor+=1
                if progress<len(PHASE_SEQUENCE) and action==PHASE_SEQUENCE[progress]:progress+=1
            elif not event['identity_safe'] or not event['writers_excluded'] or not event['guard_continuous']:
                uncertain=True;guard=False
        if not allowed:
            denied+=1;latched=True;target_write=False;owned_write=False
            if status is None:status='original-guard-or-phase-failure'
        trace.append(dict(action=action,allowed=allowed,progress=progress,forward_latched=latched,guard_held=guard,baseline_captured=captured,original_baseline=original,
            phase_state=dict(state),raw_pin=pin,owned_artifacts_retained=owned,binding_retained=binding,drained=drained,restored=restored,verified=verified,evidence=evidence,
            released=released,modeled_target_write=target_write,modeled_owned_write=owned_write,original_status=status,uncertain=uncertain))
    closed=drained and restored and verified and evidence and state==original and not uncertain
    return dict(trace=trace,model_original_baseline=original,model_raw_pin=pin,model_original_status=status,model_scoped_target_closure=closed,
        model_machine_obligations_pending=not closed,model_controller_obligations_pending=not released or uncertain,model_unknown=uncertain,model_denials=denied,
        actual_guard_acquired=False,actual_writer_exclusion_proven=False,actual_original_baseline_captured=False,actual_backups_verified=False,
        actual_dispatch_authorized=False,actual_recovery_authorized=False,actual_grant_consumed=False,actual_restoration_proven=False,
        actual_host_obligations_closed=False,actual_operational_conformance=False,actual_strong_safe_pause_confirmed=False,retry_authorized=False,publication_authorized=False)






def run_historical(history):
    with tempfile.TemporaryDirectory(prefix='step324-exact323-') as directory:
        snapshot = Path(directory)/'slack-update'
        for rel,content in history.items():
            p = snapshot/safe_relative(rel); p.parent.mkdir(parents=True,exist_ok=True); p.write_bytes(content)
        result = subprocess.run(['bash',str(snapshot/'tests/reference'/('test-'+PRIOR+'-harness.sh'))],capture_output=True)
        lines = result.stdout.decode().splitlines()
        if result.returncode or lines.count('Result: PASS (271 passes, 0 failures)')!=1 or sum(x.startswith('PASS: ') for x in lines)!=271:
            sys.stderr.buffer.write(result.stdout+result.stderr)
            raise ValueError('full exact271 predecessor acceptance failed')
        return result.stdout

def main(root,out):
    if not root.is_dir() or root.absolute()!=root.resolve():raise ValueError('unsafe repository root')
    for rel,digest in OWN_HASHES.items():exact(sha(safe_file(root,rel)),digest,'changed324 input '+rel)
    fixture=root/FIXTURE;load=lambda suffix:json.loads((fixture/(BASE+suffix)).read_bytes())
    policy,design=load('-policy.json'),load('-design.json');history=verify_history(root,policy)
    frozen=json.loads(history[FIXTURE+'/'+REQUIREMENTS_BASE+'-freeze.json']);prior=json.loads(history[FIXTURE+'/'+PRIOR+'-design.json'])
    validate_design(design,prior,frozen,history);validate_confirmation(load('-checkpoint-confirmation.json'),load('-step323-user-acceptance.json'))
    validate_tables(*[(fixture/(BASE+s)).read_bytes() for s in ['-guard-resource-window-matrix.tsv','-original-phase-delta-matrix.tsv']])
    payloads={BASE+s:(fixture/(BASE+s)).read_bytes() for s in SUFFIXES};log_name=BASE+'-predecessor-test.log'
    if not out.is_dir() or out.absolute()!=out.resolve():raise ValueError('output must exist without symlink ancestors')
    if any((out/name).exists() or (out/name).is_symlink() for name in list(payloads)+[log_name]):raise ValueError('occupied output; no overwrite')
    payloads[log_name]=run_historical(history);exact(verify_history(root,policy),history,'history changed during validation')
    for rel,digest in OWN_HASHES.items():exact(sha(safe_file(root,rel)),digest,'324 input changed during validation')
    created=[]
    try:
        for name,content in payloads.items():
            with (out/name).open('xb') as stream:created.append(out/name);stream.write(content)
    except BaseException:
        for p in reversed(created):p.unlink()
        raise
    print('exact_step323_acceptance\tPASS (271 passes, 0 failures)')
    print('step324_guarded_original_phase_design_review_status\tPASS');print('actual_guard_baseline_or_delta_proven\tno')
    print('actual_forward_or_recovery_authorized\tno');print('operational_readiness\tno');print('strong_safe_pause\tno')
    print('last_confirmed_strong_safe_pause_step\t318');print('next_stage_authorized\tno')

if __name__ == '__main__':
    try: main(Path(sys.argv[1]).absolute(),Path(sys.argv[2]).absolute())
    except (ValueError,OSError,KeyError,TypeError) as exc:
        print('ERROR: '+str(exc),file=sys.stderr);sys.exit(1)
PYREVIEW
