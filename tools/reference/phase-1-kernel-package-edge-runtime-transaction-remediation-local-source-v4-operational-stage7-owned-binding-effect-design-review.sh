#!/bin/bash
set -euo pipefail
export LC_ALL=C
script_dir=$(CDPATH= cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)
repo_root=$(CDPATH= cd -- "$script_dir/../.." && pwd -P)
if [[ $# -eq 1 && $1 == --help ]]; then
    printf 'Usage: %s --output-dir DIR\nRepository-only successor stage7 owned binding design review; no runtime authority.\n' "${0##*/}"
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

BASE = 'phase-1-kernel-package-edge-runtime-transaction-remediation-local-source-v4-operational-stage7-owned-binding-effect-design-review'
PRIOR = 'phase-1-kernel-package-edge-runtime-transaction-remediation-local-source-v4-operational-admission-handoff-and-namespace-fd-design-review'
FIXTURE = 'tests/fixtures/reference/acceptance/phase-1'
OWN_HASHES = {'docs/reference/phase-1-kernel-package-edge-runtime-transaction-remediation-local-source-v4-operational-stage7-owned-binding-effect-design-review.md': '4d24251bc5730927561d0f40ae84aa1bf6332cbaf1acd0a1743c2e323da14767', 'tests/fixtures/reference/acceptance/phase-1/phase-1-kernel-package-edge-runtime-transaction-remediation-local-source-v4-operational-stage7-owned-binding-effect-design-review-policy.json': '0175bec83633f232544ae7b9614289f48de6c71db0a9889886d69e68e9b06e1c', 'tests/fixtures/reference/acceptance/phase-1/phase-1-kernel-package-edge-runtime-transaction-remediation-local-source-v4-operational-stage7-owned-binding-effect-design-review-design.json': 'ff7428e2039927559130a6b0f58611a669f30215221aaf3887e3fa360438a494', 'tests/fixtures/reference/acceptance/phase-1/phase-1-kernel-package-edge-runtime-transaction-remediation-local-source-v4-operational-stage7-owned-binding-effect-design-review-checkpoint-confirmation.json': '878a7d53266df1723bb86356ac154021240d6c92511b80b674b6c9e10ba93e5a', 'tests/fixtures/reference/acceptance/phase-1/phase-1-kernel-package-edge-runtime-transaction-remediation-local-source-v4-operational-stage7-owned-binding-effect-design-review-step321-user-acceptance.json': '995c67c22014aabfa216eee5bb177b13d73cd064a594212d0cca06c94b850df5', 'tests/fixtures/reference/acceptance/phase-1/phase-1-kernel-package-edge-runtime-transaction-remediation-local-source-v4-operational-stage7-owned-binding-effect-design-review-stage-effect-map.tsv': 'feee1f4cd49551c7cbcb103aea1477a2ab90fcca0706e32a5f3fa01a101c2d17', 'tests/fixtures/reference/acceptance/phase-1/phase-1-kernel-package-edge-runtime-transaction-remediation-local-source-v4-operational-stage7-owned-binding-effect-design-review-binding-commit-matrix.tsv': '8c2951ab9488dc43e7a29246c8c26e0916e3fe3a863528a723c6a32a50437d49'}
CHANGELOG_PREFIX = '## Phase 1 step322 — successor stage7 owned binding effect design review — 2026-10-04\n\n- Confirmed321: dd37e79 prefix, full2251 PASS identical and ordered to prepared suite, first push correct, clean tree and two matching HEAD/origin logs. Full ID unknown; original150756-byte return and external confirmation preserved without independent host/GitHub inspection or rewriting prepared321.318 remains last confirmed strong pause.\n- Preserve1476 accepted artifacts except additive CHANGELOG prefix; nine new artifacts classify successor stage7 as owned-files. Full2251 predecessor acceptance reruns exact bytes with843/547/717 and earlier mandatory coverage intact. Frozen read-only stage7/implementation/private candidate/requirements source unchanged; old stage operation and private model already persist owned binding, reviewed as historical facts not live proof.\n- Keep successor index7/function/evidence/guard/failure/test seams and all other frozen stages unchanged, explicitly revise only successor effect and operation. Split read-only memory validation from owned intent/staging/bytes/metadata/no-replace/durability/stdout-stderr-exit writes. Traps/owned-root record/continuous guard/original baseline approved deltas/authenticated consumed-active attempt/live forward authority precede every owned write, with actual proofs pending.\n- Final symbolic evidence/candidate-binding.json stays same; add same-attempt registered staging leaf, root0700 and successor binding0600 with actual numeric owner/namespace/ancestry/aliases proof required. Exclusive create and supported no-replace final commit, complete byte/metadata/directory/storage durability and exit evidence before qualification; visible leaf/file-flush/row/status/SHA alone cannot prove this. Raw pkglist SHA pinned once, no logical-row rebind or source/target/predecessor role substitution.\n- Binding records candidate observations, not bearer dispatch/selector effect or target-readiness proof. Stage8 needs independent fresh guards/grant/real selector-helper-effect checks. Stage7 itself changes no package, but prior stage4 predecessor and stage5 isolation may remain; stage7 qualification/failure never means global restoration or no machine obligations. Known partial/unknown commit/durability/exit/loss retain owned artifacts, original forward latch/status and pending controller/possible machine obligations, no retry/recreate/blind cleanup.\n- Private finite owned-event/phase/loss and synthetic canonical frozen-row/raw-SHA binding models only. No actual owned binding/no-replace/fsync/owner/guard/source/archive/pkglist/selector/boot/target/runtime action, v2 never sourced/run. All seven capabilities/ten cross obligations operationally incomplete; six future stage7 proofs required-not-proven, actual slots and host obligations null/unobserved not absent. No machine/controller cleanup introduced by this repository stage.\n-323 expiry/revocation recovery,324 continuous guarded baseline,325 whole effect graph and326–328 model/closure/freeze remain separate. Route319–328 unchanged,329–330 optional ungranted.322 apply/tests/exact commit/push/return pending;323 preparation requires complete322 return.322 not strong pause, production/Phase2 closed and Phase1/kernel edge incomplete.\n\n'
BASELINE_JSON_SHA256 = '0846904ac7090ca617fabdee3d7ce8738139df26123923bf3e7786678a7fbf04'
CONFIRMATION_SHA256 = '878a7d53266df1723bb86356ac154021240d6c92511b80b674b6c9e10ba93e5a'
RECEIPT_SHA256 = 'd6f19ac3fc5ee0468154879d11d6b943c3089dbe4c7e21c5a76a91ba3308b5ca'
TABLE_HASHES = ['feee1f4cd49551c7cbcb103aea1477a2ab90fcca0706e32a5f3fa01a101c2d17', '8c2951ab9488dc43e7a29246c8c26e0916e3fe3a863528a723c6a32a50437d49']

REQUIREMENTS_BASE = 'phase-1-kernel-package-edge-runtime-transaction-remediation-local-source-v4-operational-requirements-freeze-and-strong-safe-pause'
DESIGN_SPEC = {'schema': 1, 'step': 322, 'scope': 'successor-stage7-owned-binding-effect-design-only', 'design_version': 'stage7-owned-binding-v1-review-not-operational-freeze', 'review_status': 'PASS-successor-effect-classification-only-implementation-and-conformance-blocked', 'selected_effect': 'owned-files', 'immutable_stage_facts': {'frozen_stage7': {'effect': 'read-only', 'evidence': {'early_buffer': False, 'exit_record': 'evidence/stages/07-bind-exact-candidate.json', 'publication_receipt_external': False, 'stderr': 'evidence/stages/07-bind-exact-candidate.stderr', 'stdout': 'evidence/stages/07-bind-exact-candidate.stdout'}, 'failure_boundary': 'stop-later-stages-preserve-original-status-run-only-safe-idempotent-restore-and-evidence-no-retry', 'function': 'bind_exact_candidate', 'guard': 'one exact eight-field target row; same-transaction source/pkglist/archive hashes before apply', 'index': 7, 'operation': 'Extract immutable accepted candidate oracle by AST in implementation design; validate one exact eight-field target row, zero unrelated candidates, source/archive/pkglist SHA; persist binding owned to same transaction.', 'stage': 'bind-exact-candidate', 'test_seams': ['stage-entry-failure', 'stage-mid-effect-failure', 'HUP-INT-TERM', 'uncatchable-loss', 'evidence-write-failure', 'cleanup-failure', 'double-cleanup']}, 'frozen_implementation_path': 'tests/fixtures/reference/acceptance/phase-1/phase-1-kernel-package-edge-runtime-transaction-remediation-local-source-v4-runtime-executor-implementation-freeze-freeze.json', 'frozen_implementation_sha256': '3b1c489d903fabe66e14acd43416eae075feb44923a1314a316e7a2c38997f41', 'frozen_binding_role': 'evidence/candidate-binding.json', 'private_model_path': 'tools/reference/phase-1-kernel-package-edge-runtime-transaction-remediation-local-source-v4-runtime-executor-failure-coverage-candidate-private.py', 'private_model_sha256': '9c6bf6d82a15eef3eb74ae8e3aa7ccfbff46af07ec0c105f6c2db4fa5402d7e4', 'private_binding_function_sha256': '8a504660cdc54d372f650fe6dc45527136b88e8a7a07cbde7def8a1f0009f3ed', 'private_binding_persists_owned_file': True, 'private_model_is_operational_implementation': False}, 'successor_stage7': {'effect': 'owned-files', 'evidence': {'early_buffer': False, 'exit_record': 'evidence/stages/07-bind-exact-candidate.json', 'publication_receipt_external': False, 'stderr': 'evidence/stages/07-bind-exact-candidate.stderr', 'stdout': 'evidence/stages/07-bind-exact-candidate.stdout'}, 'failure_boundary': 'stop-later-stages-preserve-original-status-run-only-safe-idempotent-restore-and-evidence-no-retry', 'function': 'bind_exact_candidate', 'guard': 'one exact eight-field target row; same-transaction source/pkglist/archive hashes before apply', 'index': 7, 'operation': 'Validate exact same-attempt pinned candidate observations in memory, then record and durably commit one owned binding under reviewed traps, continuous guard and original approved phase deltas; binding alone grants no target dispatch.', 'stage': 'bind-exact-candidate', 'test_seams': ['stage-entry-failure', 'stage-mid-effect-failure', 'HUP-INT-TERM', 'uncatchable-loss', 'evidence-write-failure', 'cleanup-failure', 'double-cleanup']}, 'prior_handoff_design_sha256': 'c814396b3d002f3398b1d024ab30d9b74dfa6d84aee0c87df93215f571bd1540', 'prior_admission_design_sha256': '206070db792430966f1b1654d29d7fecabaf43288f1d208b1332d5a40432726f', 'compatibility_rule': 'Only successor stage7 effect/operation clarified; exact frozen stage index/function/evidence/guard/failure/test seams and every other stage remain history unchanged; no frozen source execution or rewrite.', 'split': {'validation': 'read-only-candidate-and-original-raw-binding-checks-in-memory', 'commit': 'owned-intent-staging-byte-metadata-no-replace-durability-and-stage-evidence-writes'}, 'prerequisite_gates': ['consumed_active_attempt', 'authenticated_original_context', 'traps_armed', 'owned_root_recorded', 'continuous_guard', 'fresh_original_baseline_and_approved_deltas', 'canonical_owned_parent_and_aliases', 'source_archive_pkglist_raw_exact', 'candidate_exact_and_unrelated_zero', 'binding_absent', 'forward_grant_valid', 'all_writers_excluded', 'supported_no_replace_and_durability'], 'owned_paths': {'final_relative': 'evidence/candidate-binding.json', 'staging_relative': 'evidence/candidate-binding.<new-grant-attempt-token>.pending', 'stage_evidence': ['evidence/stages/07-bind-exact-candidate.stdout', 'evidence/stages/07-bind-exact-candidate.stderr', 'evidence/stages/07-bind-exact-candidate.json'], 'intent': 'same-attempt-owned-artifact-record-before-first-staging-byte-or-metadata-write', 'root_mode': '0700-frozen-owned-root', 'binding_mode': '0600-successor-owned-binding', 'owner': 'same-review-bound-worker-owned-root-numeric-owner-and-namespace-mapping-proof-required', 'actual_root': None, 'actual_owner': None, 'actual_parent': None, 'actual_staging_path': None, 'actual_final_path': None}, 'commit_contract': {'sequence': ['validate-exact-inputs', 'register-owned-intent', 'create-exclusive-stage', 'write-complete-bytes', 'metadata-and-data-durable', 'revalidate-pinned-inputs', 'commit-no-replace', 'directory-durability-confirmed', 'stage-exit-evidence-complete'], 'no_replace': 'exclusive-staging-and-final-commit-no-overwrite-or-force-rename; every-ancestor-parent-alias-and-content-writer-controlled-through-commit', 'durability': 'actual-supported-file-byte-metadata-directory-storage-semantics-proved-before-claiming-complete; visible-leaf-close-or-file-flush-alone-not-proof', 'payload': 'one-canonical-observation-record-from-pinned-original-context-source-archive-predecessor-baseline-and-raw-pkglist; no-secret-trust-key-or-bearer-dispatch-permission', 'eligibility': 'only-complete-known-durable-binding-and-stage-exit-evidence-qualify-stage7; stage8-requires-independent-fresh-guards-authorization-and-real-selector/effect-proof', 'grant': 'same-original-consumed-active-attempt-never-unused-or-new-grant-per-write', 'baseline': 'original-guarded-baseline-with-original-approved-stage4/5/6-deltas-not-rebound-to-predecessor-or-drift', 'raw_pkglist': 'raw-SHA-bound-once; logical-row-equivalence-cannot-rebind-changed-bytes; later-approved-regular-object-replacement-only-with-identical-bound-raw-SHA', 'stage7_target_package_effect': 'none-by-this-stage; prior-predecessor-and-configuration-effects-still-owned-and-not-yet-restored', 'failure': 'persistent-forward-latch-preserves-original-status-and-owned-partial/final-artifacts; no-repeat-commit-recreate-or-stage8-dispatch; recovery/evidence-rights-must-be-separately-reviewed323', 'unknown': 'unknown-commit-directory-durability-or-evidence-result-remains-null/pending-not-eligible; no-automatic-delete-or-rehash-as-success'}, 'failure_events': ['fail-before-write', 'input-drift', 'stage-write-failed', 'commit-unknown', 'directory-durability-unknown', 'exit-evidence-failed', 'uncatchable-loss', 'occupied-final'], 'requirements': {'no_readonly_label_for_owned_commit': True, 'traps_before_owned_write': True, 'continuous_guard_before_validation_through_commit': True, 'owned_root_and_intent_recorded_before_staging': True, 'same_consumed_active_attempt': True, 'forward_authority_revalidated': True, 'original_baseline_and_approved_deltas_preserved': True, 'all_writers_parent_aliases_and_content_controlled': True, 'exact_source_archive_predecessor_and_raw_pkglist_pinned': True, 'candidate_binding_not_selector_or_authority_proof': True, 'one_exclusive_staging_and_no_replace_commit': True, 'metadata_and_directory_storage_durability_required': True, 'unknown_commit_never_stage8_eligible': True, 'persistent_failure_latch': True, 'no_retry_recreate_rebind_or_new_grant': True, 'earlier_target_and_config_obligations_preserved': True, 'no_blind_cleanup_or_false_restoration': True, 'all_binding_and_evidence_writes_in_effect_graph': True}, 'proof_state': {'selected_successor_owned_effect': True, 'actual_binding_written': False, 'actual_parent_owner_or_alias_proven': False, 'actual_writer_exclusion_proven': False, 'actual_pinned_source_archive_or_raw_pkglist_proven': False, 'actual_no_replace_and_durability_proven': False, 'actual_selector_equivalence_or_effect_proven': False, 'actual_guarded_baseline_proven': False, 'operational_implementation_complete': False, 'operational_conformance': False, 'operational_readiness': False, 'actual_grant_consumed': False, 'actual_target_package_mutated': False, 'historical_v2_sourced_or_run': False, 'frozen_operational_bytes_rewritten': False, 'actual_live_bindings': None, 'actual_host_obligations_observed': None, 'actual_host_obligations_claimed_absent': False}, 'future_proof_obligations': [{'id': 'successor-stage7-implementation-parity', 'evidence': 'Actual new successor code/effect graph matches owned stage7 and preserved stage boundaries without running/rewriting frozen historicalv2; owned stdout/stderr/exit/intents included.', 'status': 'required-not-proven'}, {'id': 'guarded-original-phase-binding', 'evidence': 'Actual same consumed-active authenticated attempt, live forward authority, continuous guards and fresh original baseline with approved predecessor/config/pkglist deltas; no late rebind.', 'status': 'required-not-proven'}, {'id': 'actual-candidate-and-raw-inputs', 'evidence': 'Actual retained source/archive/predecessor/manifest/raw pkglist exact bytes and full candidate/selector/helper status/effect proof; row/SHA/emulator alone insufficient.', 'status': 'required-not-proven'}, {'id': 'owned-path-exclusive-durable-commit', 'evidence': 'Actual canonical ancestors/mounts/aliases/numeric owner/staging/final no-replace and supported file/metadata/directory/storage durability, with all writers excluded through consumption.', 'status': 'required-not-proven'}, {'id': 'partial-binding-and-prior-obligations', 'evidence': 'Every staging/commit/durability/evidence/loss failure preserves original latch/status and partial/final artifacts plus prior stage4/5 effects until separately authorized verified recovery; no false no-obligation closure.', 'status': 'required-not-proven'}, {'id': 'binding-consumer-and-publication-integrity', 'evidence': 'Actual later consumer revalidates original raw/context/owned artifact integrity under guards; no binding bearer dispatch, secret-key output or publication success before full restore/target closure/last receipt.', 'status': 'required-not-proven'}], 'seven_requirements_bindings': [{'capability': 'real-reference-integration-and-selector-equivalence', 'operational_conformance': False, 'policy_path': 'tests/fixtures/reference/acceptance/phase-1/phase-1-kernel-package-edge-runtime-transaction-remediation-local-source-v4-operational-reference-integration-and-selector-requirements-review-policy.json', 'policy_sha256': '9fcb69804f2d3abff675044f477b903416314bb7a195a938e45b1ee1f1260fa1', 'requirements_status': 'reviewed-not-operationally-complete', 'review_path': 'tests/fixtures/reference/acceptance/phase-1/phase-1-kernel-package-edge-runtime-transaction-remediation-local-source-v4-operational-reference-integration-and-selector-requirements-review-review.json', 'review_sha256': '69d846f1a5473cc8e2859ee7f3a242047c32d49e364601f9429054a742cdabf8', 'step': 310}, {'capability': 'namespace-command-transport-and-no-fallback', 'operational_conformance': False, 'policy_path': 'tests/fixtures/reference/acceptance/phase-1/phase-1-kernel-package-edge-runtime-transaction-remediation-local-source-v4-operational-namespace-transport-and-no-fallback-requirements-review-policy.json', 'policy_sha256': '3f321ef0ca8317cb6261d707dc158ae306ef92435430e824d77e42b9e066b8a8', 'requirements_status': 'reviewed-not-operationally-complete', 'review_path': 'tests/fixtures/reference/acceptance/phase-1/phase-1-kernel-package-edge-runtime-transaction-remediation-local-source-v4-operational-namespace-transport-and-no-fallback-requirements-review-review.json', 'review_sha256': 'ed2b6651ab1f54eaea7cd33c765f9d677a0cb257d47840237babd966281b9af9', 'step': 311}, {'capability': 'absolute-backend-path-and-SHA', 'operational_conformance': False, 'policy_path': 'tests/fixtures/reference/acceptance/phase-1/phase-1-kernel-package-edge-runtime-transaction-remediation-local-source-v4-operational-absolute-backend-identity-requirements-review-policy.json', 'policy_sha256': '8e64828bd8abfb55f36e326177c8ddb24bb0e81a3f20bf592b949f9e1a0fc80a', 'requirements_status': 'reviewed-not-operationally-complete', 'review_path': 'tests/fixtures/reference/acceptance/phase-1/phase-1-kernel-package-edge-runtime-transaction-remediation-local-source-v4-operational-absolute-backend-identity-requirements-review-review.json', 'review_sha256': 'b23906d94ad0111daf310cf563ad056020ec4066e14b341bec7bf6e0ae28dd26', 'step': 312}, {'capability': 'reviewed-platform-writer-serialization', 'operational_conformance': False, 'policy_path': 'tests/fixtures/reference/acceptance/phase-1/phase-1-kernel-package-edge-runtime-transaction-remediation-local-source-v4-operational-platform-writer-serialization-requirements-review-policy.json', 'policy_sha256': '4f387f3b9fb6c90f8b018b45fa0e3529786c5908d6a3027a2113a7a9f25d47e8', 'requirements_status': 'reviewed-not-operationally-complete', 'review_path': 'tests/fixtures/reference/acceptance/phase-1/phase-1-kernel-package-edge-runtime-transaction-remediation-local-source-v4-operational-platform-writer-serialization-requirements-review-review.json', 'review_sha256': 'ba896b35f91d1adc6692a6813652752b158eb258af3267c85e80ec024fe856f4', 'step': 313}, {'capability': 'fresh-single-use-grant-source-target-predecessor-and-boot', 'operational_conformance': False, 'policy_path': 'tests/fixtures/reference/acceptance/phase-1/phase-1-kernel-package-edge-runtime-transaction-remediation-local-source-v4-operational-fresh-single-use-grant-requirements-review-policy.json', 'policy_sha256': '3e9bdf7b20fef359781964c489aeee00749fc9039b8397c72eeb2c95c8e9a64f', 'requirements_status': 'reviewed-not-operationally-complete', 'review_path': 'tests/fixtures/reference/acceptance/phase-1/phase-1-kernel-package-edge-runtime-transaction-remediation-local-source-v4-operational-fresh-single-use-grant-requirements-review-review.json', 'review_sha256': '73c7905dede694806bf8062ff0063775f8f927e7dada91a0bf339e87061affb6', 'step': 314}, {'capability': 'real-source-and-archive-revalidation', 'operational_conformance': False, 'policy_path': 'tests/fixtures/reference/acceptance/phase-1/phase-1-kernel-package-edge-runtime-transaction-remediation-local-source-v4-operational-real-source-and-archive-revalidation-requirements-review-policy.json', 'policy_sha256': 'b8fbffd1dff20736ad71850677aa613aa557c792b42c8616f9d8fe3073c0efe2', 'requirements_status': 'reviewed-not-operationally-complete', 'review_path': 'tests/fixtures/reference/acceptance/phase-1/phase-1-kernel-package-edge-runtime-transaction-remediation-local-source-v4-operational-real-source-and-archive-revalidation-requirements-review-review.json', 'review_sha256': '36a7f9559aaa87550ed7f4b2544960df4ec71775cb3444fd6070279e4613f5f0', 'step': 315}, {'capability': 'operational-owner-and-publication-path-bindings', 'operational_conformance': False, 'policy_path': 'tests/fixtures/reference/acceptance/phase-1/phase-1-kernel-package-edge-runtime-transaction-remediation-local-source-v4-operational-owner-and-publication-path-requirements-review-policy.json', 'policy_sha256': 'b816d61589c59fefa1c35df234269c05f1698eddab6c615a99ae030356729377', 'requirements_status': 'reviewed-not-operationally-complete', 'review_path': 'tests/fixtures/reference/acceptance/phase-1/phase-1-kernel-package-edge-runtime-transaction-remediation-local-source-v4-operational-owner-and-publication-path-requirements-review-review.json', 'review_sha256': '30c9472c9b68fd6073783c678600c9c5f41730a43a6525b132c2a0d725213ecf', 'step': 316}], 'preserved_cross_obligations': [{'id': 'claim-traps-containment', 'negative_case': 'promote-review-or-private-fixture-to-resolved-claim-traps-containment', 'required_evidence': 'No local ledger before traps; no unreviewed admission socket/service inherited by isolated backend; no protocol chosen', 'scope': 'future-operational-conformance-not-executed', 'status': 'required-not-proven'}, {'id': 'guarded-baseline', 'negative_case': 'promote-review-or-private-fixture-to-resolved-guarded-baseline', 'required_evidence': 'Keep frozen stages unchanged; interstage integration and real baseline proof still required', 'scope': 'future-operational-conformance-not-executed', 'status': 'required-not-proven'}, {'id': 'binding-effect-classification', 'negative_case': 'promote-review-or-private-fixture-to-resolved-binding-effect-classification', 'required_evidence': 'Explicit owned binding effect classification and traps/guard/grant integration review before operational freeze; do not rewrite frozen bytes', 'scope': 'future-operational-conformance-not-executed', 'status': 'required-not-proven'}, {'id': 'whole-effect-graph', 'negative_case': 'promote-review-or-private-fixture-to-resolved-whole-effect-graph', 'required_evidence': 'Persistent forward failure latch and complete actual helpers/selectors/namespace FD/identity/writer graph; no fallback', 'scope': 'future-operational-conformance-not-executed', 'status': 'required-not-proven'}, {'id': 'retained-bytes-and-writers', 'negative_case': 'promote-review-or-private-fixture-to-resolved-retained-bytes-and-writers', 'required_evidence': 'Actual ancestry aliases and content/dependency writer exclusion continuously through checked-byte consumption; no self-rehash/rebind', 'scope': 'future-operational-conformance-not-executed', 'status': 'required-not-proven'}, {'id': 'same-attempt-phase-deltas', 'negative_case': 'promote-review-or-private-fixture-to-resolved-same-attempt-phase-deltas', 'required_evidence': 'Never demand unused grant per nested call or rebind baseline to foreign drift; independently verified archive roles and same-boot scope', 'scope': 'future-operational-conformance-not-executed', 'status': 'required-not-proven'}, {'id': 'pkglist-selector-status', 'negative_case': 'promote-review-or-private-fixture-to-resolved-pkglist-selector-status', 'required_evidence': 'SHA bound once; zero install-new one upgrade required; raw helper0/20 differs from frozen emulator and real mandatory upgrade20 fails', 'scope': 'future-operational-conformance-not-executed', 'status': 'required-not-proven'}, {'id': 'target-publication-controls', 'negative_case': 'promote-review-or-private-fixture-to-resolved-target-publication-controls', 'required_evidence': 'Drain children verify restore close target evidence then release; captured closed data only; separate publication controls through receipt/handoff', 'scope': 'future-operational-conformance-not-executed', 'status': 'required-not-proven'}, {'id': 'last-receipt-durability', 'negative_case': 'promote-review-or-private-fixture-to-resolved-last-receipt-durability', 'required_evidence': 'Actual supported no-replace file/meta/directory/storage semantics and trusted origin; no pair atomicity self-containing receipt or SHA authority', 'scope': 'future-operational-conformance-not-executed', 'status': 'required-not-proven'}, {'id': 'failure-recovery-rights', 'negative_case': 'promote-review-or-private-fixture-to-resolved-failure-recovery-rights', 'required_evidence': 'No blanket exemption renewal replay retry or wrong-boot restore; preserve unknown/pending obligations and backups for separately authorized recovery', 'scope': 'future-operational-conformance-not-executed', 'status': 'required-not-proven'}], 'remaining_operational_blockers': ['314-durable-claim-traps-gap-retained', 'admission-service-no-broker-FD-isolation-integration-unresolved', 'stage7-readonly-versus-owned-binding-effect-classification-unresolved', 'all-seven-capabilities-still-require-operational-implementation-and-conformance', 'actual-recovery-expiry-revocation-policy-unselected', 'actual-current-machine-and-controller-obligations-unobserved'], 'remaining_design_reviews': [323, 324, 325, 326, 327, 328], 'compatibility_scope': ['Slackware-15.0', 'Slackware-current'], 'actual_commit_primitive': None, 'actual_durability_backend': None, 'actual_binding_bytes': None, 'private_model_scope': 'finite-owned-write-and-phase-obligation-model-plus-synthetic-canonical-binding-not-filesystem-or-real-selector-proof', 'unresolved_design_edges': ['323-expiry-revocation-bounded-recovery-policy', '324-continuous-guarded-original-baseline', '325-whole-helper-and-publication-effect-graph', 'actual-inputs-owner-alias-writer-no-replace-durability-consumer-and-selector-proofs-unimplemented']}
SUFFIXES = ['-policy.json', '-design.json', '-checkpoint-confirmation.json', '-step321-user-acceptance.json', '-stage-effect-map.tsv', '-binding-commit-matrix.tsv']

PRIOR_DESIGN_SHA256 = 'c814396b3d002f3398b1d024ab30d9b74dfa6d84aee0c87df93215f571bd1540'
GATE_KEYS = ['consumed_active_attempt', 'authenticated_original_context', 'traps_armed', 'owned_root_recorded', 'continuous_guard', 'fresh_original_baseline_and_approved_deltas', 'canonical_owned_parent_and_aliases', 'source_archive_pkglist_raw_exact', 'candidate_exact_and_unrelated_zero', 'binding_absent', 'forward_grant_valid', 'all_writers_excluded', 'supported_no_replace_and_durability']

ADMISSION_BASE = 'phase-1-kernel-package-edge-runtime-transaction-remediation-local-source-v4-operational-admission-and-durable-consumption-design-review'
PRIVATE_MODEL_PATH = 'tools/reference/phase-1-kernel-package-edge-runtime-transaction-remediation-local-source-v4-runtime-executor-failure-coverage-candidate-private.py'
COMMIT_EVENTS = ['validate-exact-inputs', 'register-owned-intent', 'create-exclusive-stage', 'write-complete-bytes', 'metadata-and-data-durable', 'revalidate-pinned-inputs', 'commit-no-replace', 'directory-durability-confirmed', 'stage-exit-evidence-complete']
FAILURE_EVENTS = ['fail-before-write', 'input-drift', 'stage-write-failed', 'commit-unknown', 'directory-durability-unknown', 'exit-evidence-failed', 'uncatchable-loss', 'occupied-final']
FIXTURE_BINDING = {'origin': 'synthetic-private-binding', 'scope': 'candidate-observations-only-not-dispatch-authority', 'attempt': 'fixture-original-consumed-active-attempt', 'boot': 'fixture-original-boot-not-live', 'original_baseline': 'fixture-original-baseline', 'approved_phase_delta': 'fixture-original-predecessor-before-apply', 'source_manifest_sha256': 'cd1d9424ba1146e2e6588e4e320f2e3aed38361bb4acc3ddc9571a688597ada6', 'target_archive_sha256': 'bcdb2fd07bf253ef943a2743e5b4d8b6345d5d61c513548a4e78f1083d263429', 'predecessor_archive_sha256': 'ec4b6ffda74b2b25690f87b2e10cc68eecb718f4cf7fae4951bcd811bdab0776', 'pkglist_sha256': 'a25297d7bd903c9a3de42000f02836db1ebc40266761b89d99ee7adfa94ba36c', 'reference_backend_context': 'fixture-original-authenticated-context', 'candidate_row': 'slackware64 kernel-headers 6.18.45 x86 1 kernel-headers-6.18.45-x86-1 ./slackware64/d txz', 'candidate_count': 1, 'unrelated_count': 0, 'actual_selector_effect_proven': False, 'operational_readiness': False}
FIXTURE_RAW_ROW = 'slackware64 kernel-headers 6.18.45 x86 1 kernel-headers-6.18.45-x86-1 ./slackware64/d txz\n'
FIXTURE_RAW_SHA = 'a25297d7bd903c9a3de42000f02836db1ebc40266761b89d99ee7adfa94ba36c'

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
    exact(sha((json.dumps(c,ensure_ascii=False,sort_keys=True,indent=2)+'\n').encode()),CONFIRMATION_SHA256,'external321 confirmation')
    exact(sorted(receipt),['encoding','original_display_sha256','original_display_size_bytes','text'],'receipt fields');exact(receipt['encoding'],'utf8-json-text','receipt encoding')
    raw=receipt['text'].encode();exact(sha(raw),RECEIPT_SHA256,'original321 digest');exact(len(raw),150756,'original321 length')
    exact(receipt['original_display_sha256'],RECEIPT_SHA256,'receipt digest metadata');exact(receipt['original_display_size_bytes'],150756,'receipt size metadata')
    lines=receipt['text'].splitlines();exact(sum(x.startswith('PASS: ') for x in lines),2251,'complete2251 return');exact(lines.count('Result: PASS (2251 passes, 0 failures)'),1,'full2251 summary')
    log='dd37e79 (HEAD -> main, origin/main, origin/HEAD) Phase 1 step 321: review authenticated admission handoff and namespace descriptor isolation'
    exact(lines.count(log),2,'matching321 HEAD origin')
    if '[main dd37e79]' not in receipt['text'] or 'ec7122f..dd37e79  main -> main' not in receipt['text']:raise ValueError('missing321 commit/push')
    return True

def verify_history(root, policy):
    binding = policy['baseline_sha256_bindings']
    serialized = (json.dumps(binding, ensure_ascii=False, sort_keys=True, indent=2)+'\n').encode()
    exact(sha(serialized),BASELINE_JSON_SHA256,'exact accepted1476 manifest')
    exact(len(binding),1476,'accepted1476 file count')
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
    exact(design,DESIGN_SPEC,'exact successor owned-binding contract');exact(extract_stage_facts(history,frozen),design['immutable_stage_facts'],'actual immutable historical stage7 facts')
    exact(sha((json.dumps(prior,ensure_ascii=False,sort_keys=True,indent=2)+'\n').encode()),PRIOR_DESIGN_SHA256,'exact selected321 handoff contract')
    exact(sha(history[FIXTURE+'/'+ADMISSION_BASE+'-design.json']),design['prior_admission_design_sha256'],'exact selected320 admission contract')
    exact(design['seven_requirements_bindings'],frozen['seven_review_bindings'],'seven frozen requirements');exact(design['preserved_cross_obligations'],frozen['proof_obligations'],'all ten cross obligations')
    original=design['immutable_stage_facts']['frozen_stage7'];successor=design['successor_stage7']
    exact(original['effect'],'read-only','historical effect retained');exact(successor['effect'],'owned-files','successor owned classification')
    for key in original:
        if key not in ['effect','operation']:exact(successor[key],original[key],'preserved successor stage field '+key)
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

def extract_stage_facts(history,frozen):
    raw=history[PRIVATE_MODEL_PATH];text=raw.decode();tree=ast.parse(text)
    methods=[n for n in ast.walk(tree) if isinstance(n,ast.FunctionDef) and n.name=='bind_exact_candidate']
    if len(methods)!=1:raise ValueError('nonunique private binding function')
    source=ast.get_source_segment(text,methods[0]);persistent='exclusive(self.roles["binding"], encoded(self.binding))' in source
    spec=json.loads(history[frozen['freeze_path']])['frozen_implementation_specification']
    return dict(frozen_stage7=spec['stages'][7],frozen_implementation_path=frozen['freeze_path'],frozen_implementation_sha256=sha(history[frozen['freeze_path']]),
        frozen_binding_role=spec['path_design']['roles']['binding'],private_model_path=PRIVATE_MODEL_PATH,private_model_sha256=sha(raw),
        private_binding_function_sha256=sha(source.encode()),private_binding_persists_owned_file=persistent,private_model_is_operational_implementation=False)

def evaluate_private_binding_gate(value):
    exact(sorted(value),['conditions','origin','scope'],'binding gate fields');exact(value['origin'],'synthetic-private-fixture','binding gate origin')
    exact(value['scope'],'owned-binding-preparation-only','binding gate scope');exact(sorted(value['conditions']),sorted(GATE_KEYS),'binding prerequisites')
    if any(type(x) is not bool for x in value['conditions'].values()):raise ValueError('typed binding prerequisite')
    return dict(model_owned_binding_preparation_eligible=all(value['conditions'].values()),actual_binding_write_authorized=False,
        actual_dispatch_authorized=False,actual_grant_consumed=False,actual_guarded_baseline_proven=False,actual_operational_conformance=False,retry_authorized=False)

def evaluate_private_binding_bytes(value):
    exact(sorted(value),['binding_bytes','expected_pkglist_sha256','origin','raw_pkglist','scope'],'binding byte fields')
    exact(value['origin'],'synthetic-private-fixture','binding byte origin');exact(value['scope'],'candidate-observations-not-authority','binding byte scope')
    if type(value['raw_pkglist']) is not bytes or type(value['binding_bytes']) is not bytes or type(value['expected_pkglist_sha256']) is not str:raise ValueError('typed binding bytes')
    if len(value['binding_bytes'])>65536 or len(value['raw_pkglist'])>65536:raise ValueError('bounded private binding input')
    accepted=False
    try:
        parsed=json.loads(value['binding_bytes'].decode(),object_pairs_hook=unique_pairs)
        accepted=canonical(parsed)==value['binding_bytes'] and canonical(parsed)==canonical(FIXTURE_BINDING) and sha(value['raw_pkglist'])==FIXTURE_RAW_SHA and value['expected_pkglist_sha256']==FIXTURE_RAW_SHA
    except (ValueError,TypeError,RecursionError):accepted=False
    return dict(model_original_binding_bytes_eligible=accepted,actual_source_archive_pkglist_or_selector_proven=False,
        actual_dispatch_authorized=False,actual_binding_durability_proven=False,actual_grant_consumed=False,actual_operational_conformance=False)

def simulate_private_binding_events(value):
    exact(sorted(value),['events','origin','prior_target_phase','scope'],'binding event fields');exact(value['origin'],'synthetic-private-fixture','binding event origin')
    exact(value['scope'],'stage7-owned-effect-contract-only','binding event scope')
    if type(value['prior_target_phase']) is not str or value['prior_target_phase'] not in ['baseline','predecessor','unknown']:raise ValueError('prior phase type')
    if type(value['events']) is not list or len(value['events'])>20:raise ValueError('bounded binding schedule')
    progress=0;latched=False;unknown=False;denied=0;trace=[]
    for event in value['events']:
        if type(event) is not str or event not in COMMIT_EVENTS+FAILURE_EVENTS:raise ValueError('binding event type')
        if latched:denied+=1
        elif event in FAILURE_EVENTS:
            latched=True;unknown=event in ['commit-unknown','directory-durability-unknown','uncatchable-loss']
        elif progress<len(COMMIT_EVENTS) and event==COMMIT_EVENTS[progress]:progress+=1
        else:latched=True;denied+=1
        trace.append(dict(progress=progress,forward_latched=latched,known_owned_staging=progress>=3,known_final_visible=progress>=7))
    qualified=progress==len(COMMIT_EVENTS) and not latched
    # No stage7 event restores prior predecessor/configuration effects.
    return dict(model_stage7_qualified=qualified,modeled_commit_durability=None if unknown else progress>=8,
        modeled_owned_artifacts_preserved=progress>=3,modeled_final_visible=progress>=7,
        modeled_controller_obligations_pending=not qualified,
        modeled_possible_machine_obligations=value['prior_target_phase']!='baseline',
        modeled_prior_state_unknown=value['prior_target_phase']=='unknown',modeled_denials=denied,trace=trace,
        actual_dispatch_authorized=False,actual_binding_written=False,actual_binding_durability_proven=False,
        actual_host_obligations_closed=False,actual_operational_conformance=False,actual_strong_safe_pause_confirmed=False,retry_authorized=False,recovery_authorized=False)




def run_historical(history):
    with tempfile.TemporaryDirectory(prefix='step322-exact321-') as directory:
        snapshot = Path(directory)/'slack-update'
        for rel,content in history.items():
            p = snapshot/safe_relative(rel); p.parent.mkdir(parents=True,exist_ok=True); p.write_bytes(content)
        result = subprocess.run(['bash',str(snapshot/'tests/reference'/('test-'+PRIOR+'-harness.sh'))],capture_output=True)
        lines = result.stdout.decode().splitlines()
        if result.returncode or lines.count('Result: PASS (2251 passes, 0 failures)')!=1 or sum(x.startswith('PASS: ') for x in lines)!=2251:
            sys.stderr.buffer.write(result.stdout+result.stderr)
            raise ValueError('full exact2251 predecessor acceptance failed')
        return result.stdout

def main(root,out):
    if not root.is_dir() or root.absolute()!=root.resolve():raise ValueError('unsafe repository root')
    for rel,digest in OWN_HASHES.items():exact(sha(safe_file(root,rel)),digest,'changed322 input '+rel)
    fixture=root/FIXTURE;load=lambda suffix:json.loads((fixture/(BASE+suffix)).read_bytes());policy,design=load('-policy.json'),load('-design.json');history=verify_history(root,policy)
    frozen=json.loads(history[FIXTURE+'/'+REQUIREMENTS_BASE+'-freeze.json']);prior=json.loads(history[FIXTURE+'/'+PRIOR+'-design.json'])
    validate_design(design,prior,frozen,history);validate_confirmation(load('-checkpoint-confirmation.json'),load('-step321-user-acceptance.json'))
    validate_tables(*[(fixture/(BASE+s)).read_bytes() for s in ['-stage-effect-map.tsv','-binding-commit-matrix.tsv']])
    payloads={BASE+s:(fixture/(BASE+s)).read_bytes() for s in SUFFIXES};log_name=BASE+'-predecessor-test.log'
    if not out.is_dir() or out.absolute()!=out.resolve():raise ValueError('output must exist without symlink ancestors')
    if any((out/name).exists() or (out/name).is_symlink() for name in list(payloads)+[log_name]):raise ValueError('occupied output; no overwrite')
    payloads[log_name]=run_historical(history);exact(verify_history(root,policy),history,'history changed during validation')
    for rel,digest in OWN_HASHES.items():exact(sha(safe_file(root,rel)),digest,'322 input changed during validation')
    created=[]
    try:
        for name,content in payloads.items():
            with (out/name).open('xb') as stream:created.append(out/name);stream.write(content)
    except BaseException:
        for p in reversed(created):p.unlink()
        raise
    print('exact_step321_acceptance\tPASS (2251 passes, 0 failures)')
    print('step322_owned_binding_design_review_status\tPASS')
    print('selected_successor_stage7_effect\towned-files')
    print('actual_binding_write_or_dispatch_authorized\tno')
    print('actual_no_replace_and_durability_proven\tno')
    print('operational_readiness\tno');print('strong_safe_pause\tno');print('last_confirmed_strong_safe_pause_step\t318');print('next_stage_authorized\tno')

if __name__ == '__main__':
    try: main(Path(sys.argv[1]).absolute(),Path(sys.argv[2]).absolute())
    except (ValueError,OSError,KeyError,TypeError) as exc:
        print('ERROR: '+str(exc),file=sys.stderr);sys.exit(1)
PYREVIEW
