#!/bin/bash
set -euo pipefail
export LC_ALL=C
script_dir=$(CDPATH= cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)
repo_root=$(CDPATH= cd -- "$script_dir/../.." && pwd -P)
if [[ $# -eq 1 && $1 == --help ]]; then
    printf 'Usage: %s --output-dir DIR\nRepository-only authenticated handoff and descriptor design review; no runtime authority.\n' "${0##*/}"
    exit 0
fi
[[ $# -eq 2 && $1 == --output-dir && -n $2 ]] || { printf 'ERROR: expected --output-dir DIR\n' >&2; exit 2; }
python3 - "$repo_root" "$2" <<'PYREVIEW'
import math
import hashlib
import json
import subprocess
import sys
import tempfile
from pathlib import Path

BASE = 'phase-1-kernel-package-edge-runtime-transaction-remediation-local-source-v4-operational-admission-handoff-and-namespace-fd-design-review'
PRIOR = 'phase-1-kernel-package-edge-runtime-transaction-remediation-local-source-v4-operational-admission-and-durable-consumption-design-review'
FIXTURE = 'tests/fixtures/reference/acceptance/phase-1'
OWN_HASHES = {'docs/reference/phase-1-kernel-package-edge-runtime-transaction-remediation-local-source-v4-operational-admission-handoff-and-namespace-fd-design-review.md': 'eb22992b6713fbbcb81d1979671ca20a4bbec665cd6f921332d8dc6288248932', 'tests/fixtures/reference/acceptance/phase-1/phase-1-kernel-package-edge-runtime-transaction-remediation-local-source-v4-operational-admission-handoff-and-namespace-fd-design-review-policy.json': 'fc3a3cf2996f5fa9d2d837e45966ecc0daf67d6bb4d5b5760dee5921251e2ace', 'tests/fixtures/reference/acceptance/phase-1/phase-1-kernel-package-edge-runtime-transaction-remediation-local-source-v4-operational-admission-handoff-and-namespace-fd-design-review-design.json': 'c814396b3d002f3398b1d024ab30d9b74dfa6d84aee0c87df93215f571bd1540', 'tests/fixtures/reference/acceptance/phase-1/phase-1-kernel-package-edge-runtime-transaction-remediation-local-source-v4-operational-admission-handoff-and-namespace-fd-design-review-checkpoint-confirmation.json': '19a633be41b20bd8046365a7733698ecc2d7cd50b2d1964fcdf02e720336fcb4', 'tests/fixtures/reference/acceptance/phase-1/phase-1-kernel-package-edge-runtime-transaction-remediation-local-source-v4-operational-admission-handoff-and-namespace-fd-design-review-step320-user-acceptance.json': '73d7c5d0303963d6017c9e1d91f945a8ed1f3d22dfd101d96e378f98fd9d183b', 'tests/fixtures/reference/acceptance/phase-1/phase-1-kernel-package-edge-runtime-transaction-remediation-local-source-v4-operational-admission-handoff-and-namespace-fd-design-review-descriptor-policy.tsv': 'ba3e0bcec36177ff324a4f01ecf952166983b9f0adf302e4ee3f071b3144d672', 'tests/fixtures/reference/acceptance/phase-1/phase-1-kernel-package-edge-runtime-transaction-remediation-local-source-v4-operational-admission-handoff-and-namespace-fd-design-review-handoff-gates.tsv': '60e997d1a7d80e3eba7a3247b2c84107aedea3a0fe36b177bdf27542daea77a5'}
CHANGELOG_PREFIX = '## Phase 1 step321 — authenticated admission handoff and namespace FD design review — 2026-10-04\n\n- Confirmed320: ec7122f prefix, full843 PASS identical and ordered to prepared suite, first push correct, clean tree and two matching HEAD/origin logs. Full ID unknown; original53803-byte return and external confirmation preserved without independent host/GitHub inspection or rewriting prepared320.318 remains last confirmed strong pause.\n- Preserve1467 accepted artifacts except additive CHANGELOG prefix; nine new artifacts select a bounded offline handoff contract. Full843 predecessor suite reruns exact accepted bytes with547/717 and all independent mandatory coverage intact. All seven requirements, ten cross obligations and frozen worker/source bytes unchanged;320 consumption/launch contract remains exact.\n- Select one-way anonymous bootstrap pipe into reviewed worker supervisor memory; symbolic FD3, raw64KiB maximum,10-second deadline, exactly one canonical UTF8 JSON envelope and complete EOF. Authenticate complete domain/version/purpose/original issuer/service/epoch/grant/attempt/launch/boot/worker/scope context using independently provisioned verifier/trust root and independent one-shot launch origin; receipt cannot define expected scope or become bearer dispatch authority.\n- Read/verify/close bootstrap in memory-only stage0, on every success/failure/loss/signal path before commands; service writer endpoint never inherited. Stage1 worker traps precede owned writes,324 fresh guarded baseline remains separate. No socket/RPC callback from worker, no retry/reread/rebind/relaunch after missing or invalid context; unknown close/child/controller status retains pending obligations and blocks dispatch.\n- Every backend/helper/restore command requires exact namespace transport and explicit descriptor object/peer/origin/alias/lifetime allowlist, not FD numbers or close-on-exec flags. Controlled012 streams must have no service/host escape; separately reviewed retained read-only code FDs require interpreter/consumption/close-phase proof and cannot leak to unreviewed helpers. All FD/process/cwd/env/mount/network routes to admission service excluded, no host fallback.\n- Private canonical synthetic context parser, typed FD classification and finite eligibility/loss gates only; no actual signature verification, pipe/timer/FD/namespace/worker/service/grant action or proof. Real mechanisms/key provisioning/interpreter lifetime/content writer exclusion and independent15.0/current conformance still required. Unknown host obligations/live slots null, not absent. No new machine/controller cleanup by this repository-only stage, v2 never sourced/run.\n- Separate322 successor stage7 owned effect,323 expiry/revocation recovery,324 guarded baseline,325 whole effect graph and326–328 model/closure/freeze remain planned only. Route319–328 unchanged,329–330 optional ungranted.321 application/tests/exact commit/push/return pending;322 preparation requires complete321 return.321 is not strong pause; production/Phase2 closed, Phase1/kernel edge incomplete.\n\n'
BASELINE_JSON_SHA256 = 'a2462fcc42d4dd1354a2cbbb70cbb49db81d3b90be37484973cf5254f506d25f'
CONFIRMATION_SHA256 = '19a633be41b20bd8046365a7733698ecc2d7cd50b2d1964fcdf02e720336fcb4'
RECEIPT_SHA256 = '38b92448b2493acbc28ab1fcb7c5231af1aef659d629c274d7b24667b1c55702'
TABLE_HASHES = ['ba3e0bcec36177ff324a4f01ecf952166983b9f0adf302e4ee3f071b3144d672', '60e997d1a7d80e3eba7a3247b2c84107aedea3a0fe36b177bdf27542daea77a5']

REQUIREMENTS_BASE = 'phase-1-kernel-package-edge-runtime-transaction-remediation-local-source-v4-operational-requirements-freeze-and-strong-safe-pause'
DESIGN_SPEC = {'schema': 1, 'step': 321, 'scope': 'authenticated-offline-handoff-and-descriptor-isolation-design-only', 'design_version': 'admission-handoff-v1-review-not-operational-freeze', 'selected_handoff': 'single-bounded-one-way-anonymous-bootstrap-pipe-into-worker-supervisor-memory', 'review_status': 'PASS-design-contract-only-implementation-and-conformance-blocked', 'prior_admission_design_sha256': '206070db792430966f1b1654d29d7fecabaf43288f1d208b1332d5a40432726f', 'bootstrap': {'symbolic_read_fd': 3, 'maximum_raw_bytes': 65536, 'deadline_seconds': 10, 'payload_format': 'one-canonical-UTF8-JSON-envelope-followed-by-EOF', 'canonical_form': 'ASCII-escaped-JSON-sort-keys-compact-separators-no-trailing-bytes-version-bound', 'parser_policy': 'reject-duplicate-or-extra-fields-invalid-encoding-oversize-incomplete-input-bad-types-and-noncanonical-bytes', 'trusted_receiver': 'reviewed-worker-supervisor-from-the-already-spent320-launch-slot', 'producer': 'independently-authenticated-admission-service-after-durable-consumption-and-slot-spend', 'process_effect': 'read-bounded-buffer-close-read-end-and-clear-authority-env-only-no-worker-filesystem-write', 'closure': 'close-bootstrap-read-end-on-every-success-failure-timeout-or-signal-path-before-child-exec; writer-end-never-inherited-by-worker', 'limits_scope': 'selected-symbolic-contract-limits-not-proven-real-stream-timer-or-signal-behavior'}, 'authentication': {'purpose_domain': 'slack-update/successor-admission-context-only', 'covered_fields': ['protocol', 'purpose', 'issuer', 'service_identity', 'service_epoch', 'grant_id', 'attempt_id', 'launch_slot', 'launch_instance', 'grant_state', 'launch_state', 'boot_binding', 'worker_identity', 'scope_bindings'], 'signature_scope': 'domain-protocol-version-purpose-key-identity-and-complete-original-canonical-context-bytes', 'trust_source': 'independently-provisioned-reviewed-verifier-and-trust-root-not-receipt-source-tree-path-env-or-self-rehash', 'algorithms': 'actual-signature-canonicalization-parser-and-key-provisioning-implementation-still-require-separate-selection-and-proof', 'receipt_not_bearer_dispatch_capability': True, 'receipt_not_fresh_target_or_storage_proof': True, 'independent_one_shot_launch_origin_required': True, 'no_admission_socket_or_online_RPC_for_worker': True}, 'receipt_binding_rule': 'Compare authenticated complete original context to independent reviewed launch/grant bindings; no acceptance of a receipt that defines its own expected identity or scope.', 'lifecycle': ['320-authenticate-and-durably-consume', '320-durably-spend-launch-slot', '320-invoke-one-reviewed-worker', 'worker-stage0-bounded-read-authenticate-original-context', 'worker-stage0-close-bootstrap-on-every-path', 'worker-stage1-install-traps', '324-continuous-exclusion-and-fresh-original-baseline', 'sanitize-every-child-FD-environment-cwd-and-process-context', 'reviewed-namespace-transport-no-fallback', 'consume-reviewed-retained-backend-code-and-drain-owned-streams'], 'fd_policy': {'standard_FD_numbers_not_safety_proof': True, 'allowlist': 'exact-bound-roles-object-kinds-origins-aliases-and-lifetimes-only-not-numeric-FD-shortcut', 'required_stream_roles': ['stdin', 'stdout', 'stderr'], 'streams': 'reviewed-bounded-isolated-command-stream-pipes-with-no-service-peer-or-host-escape', 'retained_code': 'only-separately-reviewed-bound-read-only-code-objects-with-reviewed-origin-aliases-interpreter-consumption-and-close-phase', 'retained_code_FD_alone_not_identity_or_immutability_proof': True, 'unreviewed_helpers_cannot_inherit_retained_code_or_bootstrap': True, 'denied': ['bootstrap-input', 'bootstrap-writer', 'admission-socket', 'RPC-channel', 'service-ledger-or-trust-key', 'host-directory', 'pid-handle', 'namespace-handle', 'unknown-or-aliased-resource'], 'backend_cannot_reach_service_via_FD_mount_path_network_cwd_env_or_process_handles': True, 'no_close_on_exec_only_inference': True, 'all_nested_helpers_and_restore_paths_in_effect_graph': True}, 'requirements': {'memory_only_stage0': True, 'no_local_worker_ledger_before_traps': True, 'one_bounded_context_read_no_reread_or_rebind': True, 'all_auth_fields_covered': True, 'independent_launch_origin_verified_before_any_dispatch': True, 'bootstrap_closed_before_every_command': True, 'no_service_capability_in_isolated_backend': True, 'FD_numbers_modes_names_or_namespace_markers_not_proof': True, 'every_command_uses_reviewed_namespace_transport': True, 'no_host_fallback': True, 'full_helper_and_interpreter_effect_graph_required': True, 'source_backend_bytes_and_writers_still_separately_proven': True, 'failed_handoff_does_not_unconsume_or_relaunch': True, 'unknown_child_and_controller_obligations_preserved': True, 'original_failure_status_preserved': True, 'recovery_policy_not_granted': True}, 'loss_policy': {'lost_or_invalid_receipt': 'already-consumed-grant-stays-burned-no-dispatch-replay-or-new-launch; preserve-service-and-worker-evidence', 'timeout_or_unknown_EOF': 'fail-closed-no-owned-worker-write-at-stage0; unknown-reader-child-status-or-service-evidence-remains-pending', 'acknowledgement': 'optional-bounded-observation-never-authority-to-relaunch-or-readmit', 'close_or_child_status_unknown': 'do-not-claim-containment-or-machine/controller-closure; no-command-dispatch', 'service_restart': '320-durable-grant-and-launch-slot-state-is-not-reopened-by-lost-context-or-receipt', 'expiry_revocation': '323-policy-pending; authentication-does-not-exempt-expiry-revocation-or-wrong-boot', 'recovery': 'bounded-issuer-reviewed-recovery-not-chosen-or-authorized-here'}, 'proof_state': {'selected_handoff_contract': True, 'actual_authentication_proven': False, 'actual_bounded_pipe_proven': False, 'actual_deadline_or_signal_closure_proven': False, 'actual_independent_launch_origin_proven': False, 'actual_FD_alias_and_ancestry_proven': False, 'actual_namespace_transport_and_containment_proven': False, 'actual_interpreter_and_helper_FD_lifetimes_proven': False, 'actual_retained_checked_byte_and_writer_exclusion_proven': False, 'operational_implementation_complete': False, 'operational_conformance': False, 'operational_readiness': False, 'actual_worker_invoked': False, 'actual_namespace_created': False, 'actual_grant_consumed': False, 'historical_v2_sourced_or_run': False, 'frozen_operational_bytes_rewritten': False, 'actual_live_bindings': None, 'actual_host_obligations_observed': None, 'actual_host_obligations_claimed_absent': False}, 'future_proof_obligations': [{'id': 'authentic-original-context-and-launch', 'evidence': 'Actual verifier/key provisioning and complete canonical authenticated fields plus independent real service/epoch/attempt/worker launch provenance; no receipt self-binding or bearer dispatch.', 'status': 'required-not-proven'}, {'id': 'bounded-pipe-lifetime', 'evidence': 'Actual complete bounded read/EOF/timer/signal handling and producer/reader closure on every path, no writer duplication, no pre-traps worker write or admission RPC.', 'status': 'required-not-proven'}, {'id': 'descriptor-object-capability-inventory', 'evidence': 'Actual child FD/object/peer/origin/mode/alias/ancestor/lifetime inventory, standard stream peer controls and reviewed read-only interpreter/code retention with close before unreviewed helper.', 'status': 'required-not-proven'}, {'id': 'whole-namespace-and-process-containment', 'evidence': 'Actual exact command transport and no host fallback for all nested helpers/restores; service unreachable through FD/process/cwd/env/mount/network paths, with guard and no competing writers.', 'status': 'required-not-proven'}, {'id': 'handoff-loss-no-replay', 'evidence': 'Actual loss/timeout/unknown-child schedules preserve320 consumed grant/launch slot and original status/evidence/pending obligations without new grant, reread or relaunch.', 'status': 'required-not-proven'}, {'id': 'platform-interpreter-and-content-consumption', 'evidence': 'Separate15.0/current supported-version verification of retained checked bytes, script/interpreter/dependencies, aliases and writer exclusion throughout every consumption; namespace/FD/SHA alone insufficient.', 'status': 'required-not-proven'}], 'seven_requirements_bindings': [{'capability': 'real-reference-integration-and-selector-equivalence', 'operational_conformance': False, 'policy_path': 'tests/fixtures/reference/acceptance/phase-1/phase-1-kernel-package-edge-runtime-transaction-remediation-local-source-v4-operational-reference-integration-and-selector-requirements-review-policy.json', 'policy_sha256': '9fcb69804f2d3abff675044f477b903416314bb7a195a938e45b1ee1f1260fa1', 'requirements_status': 'reviewed-not-operationally-complete', 'review_path': 'tests/fixtures/reference/acceptance/phase-1/phase-1-kernel-package-edge-runtime-transaction-remediation-local-source-v4-operational-reference-integration-and-selector-requirements-review-review.json', 'review_sha256': '69d846f1a5473cc8e2859ee7f3a242047c32d49e364601f9429054a742cdabf8', 'step': 310}, {'capability': 'namespace-command-transport-and-no-fallback', 'operational_conformance': False, 'policy_path': 'tests/fixtures/reference/acceptance/phase-1/phase-1-kernel-package-edge-runtime-transaction-remediation-local-source-v4-operational-namespace-transport-and-no-fallback-requirements-review-policy.json', 'policy_sha256': '3f321ef0ca8317cb6261d707dc158ae306ef92435430e824d77e42b9e066b8a8', 'requirements_status': 'reviewed-not-operationally-complete', 'review_path': 'tests/fixtures/reference/acceptance/phase-1/phase-1-kernel-package-edge-runtime-transaction-remediation-local-source-v4-operational-namespace-transport-and-no-fallback-requirements-review-review.json', 'review_sha256': 'ed2b6651ab1f54eaea7cd33c765f9d677a0cb257d47840237babd966281b9af9', 'step': 311}, {'capability': 'absolute-backend-path-and-SHA', 'operational_conformance': False, 'policy_path': 'tests/fixtures/reference/acceptance/phase-1/phase-1-kernel-package-edge-runtime-transaction-remediation-local-source-v4-operational-absolute-backend-identity-requirements-review-policy.json', 'policy_sha256': '8e64828bd8abfb55f36e326177c8ddb24bb0e81a3f20bf592b949f9e1a0fc80a', 'requirements_status': 'reviewed-not-operationally-complete', 'review_path': 'tests/fixtures/reference/acceptance/phase-1/phase-1-kernel-package-edge-runtime-transaction-remediation-local-source-v4-operational-absolute-backend-identity-requirements-review-review.json', 'review_sha256': 'b23906d94ad0111daf310cf563ad056020ec4066e14b341bec7bf6e0ae28dd26', 'step': 312}, {'capability': 'reviewed-platform-writer-serialization', 'operational_conformance': False, 'policy_path': 'tests/fixtures/reference/acceptance/phase-1/phase-1-kernel-package-edge-runtime-transaction-remediation-local-source-v4-operational-platform-writer-serialization-requirements-review-policy.json', 'policy_sha256': '4f387f3b9fb6c90f8b018b45fa0e3529786c5908d6a3027a2113a7a9f25d47e8', 'requirements_status': 'reviewed-not-operationally-complete', 'review_path': 'tests/fixtures/reference/acceptance/phase-1/phase-1-kernel-package-edge-runtime-transaction-remediation-local-source-v4-operational-platform-writer-serialization-requirements-review-review.json', 'review_sha256': 'ba896b35f91d1adc6692a6813652752b158eb258af3267c85e80ec024fe856f4', 'step': 313}, {'capability': 'fresh-single-use-grant-source-target-predecessor-and-boot', 'operational_conformance': False, 'policy_path': 'tests/fixtures/reference/acceptance/phase-1/phase-1-kernel-package-edge-runtime-transaction-remediation-local-source-v4-operational-fresh-single-use-grant-requirements-review-policy.json', 'policy_sha256': '3e9bdf7b20fef359781964c489aeee00749fc9039b8397c72eeb2c95c8e9a64f', 'requirements_status': 'reviewed-not-operationally-complete', 'review_path': 'tests/fixtures/reference/acceptance/phase-1/phase-1-kernel-package-edge-runtime-transaction-remediation-local-source-v4-operational-fresh-single-use-grant-requirements-review-review.json', 'review_sha256': '73c7905dede694806bf8062ff0063775f8f927e7dada91a0bf339e87061affb6', 'step': 314}, {'capability': 'real-source-and-archive-revalidation', 'operational_conformance': False, 'policy_path': 'tests/fixtures/reference/acceptance/phase-1/phase-1-kernel-package-edge-runtime-transaction-remediation-local-source-v4-operational-real-source-and-archive-revalidation-requirements-review-policy.json', 'policy_sha256': 'b8fbffd1dff20736ad71850677aa613aa557c792b42c8616f9d8fe3073c0efe2', 'requirements_status': 'reviewed-not-operationally-complete', 'review_path': 'tests/fixtures/reference/acceptance/phase-1/phase-1-kernel-package-edge-runtime-transaction-remediation-local-source-v4-operational-real-source-and-archive-revalidation-requirements-review-review.json', 'review_sha256': '36a7f9559aaa87550ed7f4b2544960df4ec71775cb3444fd6070279e4613f5f0', 'step': 315}, {'capability': 'operational-owner-and-publication-path-bindings', 'operational_conformance': False, 'policy_path': 'tests/fixtures/reference/acceptance/phase-1/phase-1-kernel-package-edge-runtime-transaction-remediation-local-source-v4-operational-owner-and-publication-path-requirements-review-policy.json', 'policy_sha256': 'b816d61589c59fefa1c35df234269c05f1698eddab6c615a99ae030356729377', 'requirements_status': 'reviewed-not-operationally-complete', 'review_path': 'tests/fixtures/reference/acceptance/phase-1/phase-1-kernel-package-edge-runtime-transaction-remediation-local-source-v4-operational-owner-and-publication-path-requirements-review-review.json', 'review_sha256': '30c9472c9b68fd6073783c678600c9c5f41730a43a6525b132c2a0d725213ecf', 'step': 316}], 'preserved_cross_obligations': [{'id': 'claim-traps-containment', 'negative_case': 'promote-review-or-private-fixture-to-resolved-claim-traps-containment', 'required_evidence': 'No local ledger before traps; no unreviewed admission socket/service inherited by isolated backend; no protocol chosen', 'scope': 'future-operational-conformance-not-executed', 'status': 'required-not-proven'}, {'id': 'guarded-baseline', 'negative_case': 'promote-review-or-private-fixture-to-resolved-guarded-baseline', 'required_evidence': 'Keep frozen stages unchanged; interstage integration and real baseline proof still required', 'scope': 'future-operational-conformance-not-executed', 'status': 'required-not-proven'}, {'id': 'binding-effect-classification', 'negative_case': 'promote-review-or-private-fixture-to-resolved-binding-effect-classification', 'required_evidence': 'Explicit owned binding effect classification and traps/guard/grant integration review before operational freeze; do not rewrite frozen bytes', 'scope': 'future-operational-conformance-not-executed', 'status': 'required-not-proven'}, {'id': 'whole-effect-graph', 'negative_case': 'promote-review-or-private-fixture-to-resolved-whole-effect-graph', 'required_evidence': 'Persistent forward failure latch and complete actual helpers/selectors/namespace FD/identity/writer graph; no fallback', 'scope': 'future-operational-conformance-not-executed', 'status': 'required-not-proven'}, {'id': 'retained-bytes-and-writers', 'negative_case': 'promote-review-or-private-fixture-to-resolved-retained-bytes-and-writers', 'required_evidence': 'Actual ancestry aliases and content/dependency writer exclusion continuously through checked-byte consumption; no self-rehash/rebind', 'scope': 'future-operational-conformance-not-executed', 'status': 'required-not-proven'}, {'id': 'same-attempt-phase-deltas', 'negative_case': 'promote-review-or-private-fixture-to-resolved-same-attempt-phase-deltas', 'required_evidence': 'Never demand unused grant per nested call or rebind baseline to foreign drift; independently verified archive roles and same-boot scope', 'scope': 'future-operational-conformance-not-executed', 'status': 'required-not-proven'}, {'id': 'pkglist-selector-status', 'negative_case': 'promote-review-or-private-fixture-to-resolved-pkglist-selector-status', 'required_evidence': 'SHA bound once; zero install-new one upgrade required; raw helper0/20 differs from frozen emulator and real mandatory upgrade20 fails', 'scope': 'future-operational-conformance-not-executed', 'status': 'required-not-proven'}, {'id': 'target-publication-controls', 'negative_case': 'promote-review-or-private-fixture-to-resolved-target-publication-controls', 'required_evidence': 'Drain children verify restore close target evidence then release; captured closed data only; separate publication controls through receipt/handoff', 'scope': 'future-operational-conformance-not-executed', 'status': 'required-not-proven'}, {'id': 'last-receipt-durability', 'negative_case': 'promote-review-or-private-fixture-to-resolved-last-receipt-durability', 'required_evidence': 'Actual supported no-replace file/meta/directory/storage semantics and trusted origin; no pair atomicity self-containing receipt or SHA authority', 'scope': 'future-operational-conformance-not-executed', 'status': 'required-not-proven'}, {'id': 'failure-recovery-rights', 'negative_case': 'promote-review-or-private-fixture-to-resolved-failure-recovery-rights', 'required_evidence': 'No blanket exemption renewal replay retry or wrong-boot restore; preserve unknown/pending obligations and backups for separately authorized recovery', 'scope': 'future-operational-conformance-not-executed', 'status': 'required-not-proven'}], 'remaining_operational_blockers': ['314-durable-claim-traps-gap-retained', 'admission-service-no-broker-FD-isolation-integration-unresolved', 'stage7-readonly-versus-owned-binding-effect-classification-unresolved', 'all-seven-capabilities-still-require-operational-implementation-and-conformance', 'actual-recovery-expiry-revocation-policy-unselected', 'actual-current-machine-and-controller-obligations-unobserved'], 'remaining_design_reviews': [322, 323, 324, 325, 326, 327, 328], 'actual_pipe': None, 'actual_signature_algorithm': None, 'actual_verifier': None, 'actual_trust_root': None, 'actual_namespace': None, 'actual_FD_inventory': None, 'actual_worker_command': None, 'compatibility_scope': ['Slackware-15.0', 'Slackware-current'], 'private_model_scope': 'canonical-synthetic-context-finite-typed-FD-and-gate-model-not-cryptography-OS-FDs-streams-timers-or-live-authority', 'unresolved_design_edges': ['322-stage7-owned-effect-successor', '323-expiry-revocation-recovery-policy', '324-continuous-guarded-baseline', '325-whole-service-helper-interpreter-effect-graph', 'actual-storage-launch-signature-key-parser-pipe-FD-namespace-primitives-not-selected-or-proven']}
SUFFIXES = ['-policy.json', '-design.json', '-checkpoint-confirmation.json', '-step320-user-acceptance.json', '-descriptor-policy.tsv', '-handoff-gates.tsv']

PRIOR_DESIGN_SHA256 = '206070db792430966f1b1654d29d7fecabaf43288f1d208b1332d5a40432726f'
FIXTURE_ENVELOPE = {'body': {'protocol': 'admission-handoff-v1', 'purpose': 'slack-update/successor-admission-context-only', 'issuer': 'fixture-independent-issuer', 'service_identity': 'fixture-reviewed-service', 'service_epoch': 'fixture-current-service-epoch', 'grant_id': 'fixture-original-grant', 'attempt_id': 'fixture-consumed-active-attempt', 'launch_slot': 'fixture-durably-spent-slot', 'launch_instance': 'fixture-independently-verified-launch-instance', 'grant_state': 'consumed-active', 'launch_state': 'spent', 'boot_binding': 'fixture-current-boot-not-a-live-UUID', 'worker_identity': 'fixture-reviewed-worker-bytes', 'scope_bindings': {'source': 'fixture-original-source', 'target': 'fixture-original-target', 'predecessor': 'fixture-original-predecessor', 'baseline': 'fixture-original-baseline', 'reference': 'fixture-original-reference', 'backend': 'fixture-original-backend', 'namespace': 'fixture-original-namespace', 'guard': 'fixture-original-guard', 'owner-paths': 'fixture-original-owner-paths', 'publication-paths': 'fixture-original-publication-paths', 'approved-phase-deltas': 'fixture-original-approved-phase-deltas'}}, 'signature': 'fixture-detached-signature-not-real-cryptography', 'key_id': 'fixture-independent-trust-root'}
FIXTURE_STREAMS = [{'fd': 0, 'kind': 'pipe', 'role': 'stdin', 'origin': 'reviewed-isolated-stream', 'reviewed': True, 'service_reachable': False, 'alias_known': True, 'lifetime': 'bounded-command-stream'}, {'fd': 1, 'kind': 'pipe', 'role': 'stdout', 'origin': 'reviewed-isolated-stream', 'reviewed': True, 'service_reachable': False, 'alias_known': True, 'lifetime': 'bounded-command-stream'}, {'fd': 2, 'kind': 'pipe', 'role': 'stderr', 'origin': 'reviewed-isolated-stream', 'reviewed': True, 'service_reachable': False, 'alias_known': True, 'lifetime': 'bounded-command-stream'}]
FIXTURE_RETAINED_CODE = {'fd': 7, 'kind': 'read-only-file', 'role': 'retained-code', 'origin': 'reviewed-bound-code-object', 'reviewed': True, 'service_reachable': False, 'alias_known': True, 'lifetime': 'until-reviewed-consumption-then-close-before-unreviewed-helper-dispatch'}
GATE_KEYS = ['receipt_authenticated', 'exact_original_context', 'independent_launch_origin', 'within_input_bound', 'complete_EOF_before_deadline', 'bootstrap_closed', 'worker_traps_armed', 'guarded_fresh_baseline', 'all_child_descriptors_reviewed', 'namespace_transport_reviewed', 'no_host_fallback']

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
    exact(sha((json.dumps(c,ensure_ascii=False,sort_keys=True,indent=2)+'\n').encode()),CONFIRMATION_SHA256,'external320 confirmation')
    exact(sorted(receipt),['encoding','original_display_sha256','original_display_size_bytes','text'],'receipt fields');exact(receipt['encoding'],'utf8-json-text','receipt encoding')
    raw=receipt['text'].encode();exact(sha(raw),RECEIPT_SHA256,'original320 digest');exact(len(raw),53803,'original320 length')
    exact(receipt['original_display_sha256'],RECEIPT_SHA256,'receipt digest metadata');exact(receipt['original_display_size_bytes'],53803,'receipt size metadata')
    lines=receipt['text'].splitlines();exact(sum(x.startswith('PASS: ') for x in lines),843,'complete843 return');exact(lines.count('Result: PASS (843 passes, 0 failures)'),1,'full843 summary')
    log='ec7122f (HEAD -> main, origin/main, origin/HEAD) Phase 1 step 320: review external admission and durable single-use consumption design'
    exact(lines.count(log),2,'matching320 HEAD origin')
    if '[main ec7122f]' not in receipt['text'] or 'ef0a34b..ec7122f  main -> main' not in receipt['text']:raise ValueError('missing320 commit/push')
    return True

def verify_history(root, policy):
    binding = policy['baseline_sha256_bindings']
    serialized = (json.dumps(binding, ensure_ascii=False, sort_keys=True, indent=2)+'\n').encode()
    exact(sha(serialized),BASELINE_JSON_SHA256,'exact accepted1467 manifest')
    exact(len(binding),1467,'accepted1467 file count')
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

def validate_design(design,prior,frozen):
    exact(design,DESIGN_SPEC,'exact selected handoff and FD contract')
    exact(sha((json.dumps(prior,ensure_ascii=False,sort_keys=True,indent=2)+'\n').encode()),PRIOR_DESIGN_SHA256,'exact selected320 admission contract')
    exact(design['seven_requirements_bindings'],frozen['seven_review_bindings'],'seven exact frozen requirements')
    exact(design['preserved_cross_obligations'],frozen['proof_obligations'],'all ten unresolved cross obligations')
    exact(design['remaining_operational_blockers'],frozen['remaining_operational_blockers'],'operational blockers preserved')
    exact(prior['proof_state']['actual_claim_durability_proven'],False,'no320 durability overclaim')
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

def evaluate_private_context(value):
    exact(sorted(value),['elapsed_seconds','independent_launch_origin','origin','raw','scope','signature_ok','stream_EOF'],'context fields')
    exact(value['origin'],'synthetic-private-fixture','context origin');exact(value['scope'],'offline-context-contract-not-real-cryptography','context scope')
    for key in ['signature_ok','stream_EOF','independent_launch_origin']:
        if type(value[key]) is not bool:raise ValueError('typed context condition')
    if type(value['raw']) is not bytes:raise ValueError('raw byte input')
    if type(value['elapsed_seconds']) not in [int,float] or not math.isfinite(value['elapsed_seconds']) or value['elapsed_seconds']<0:raise ValueError('bounded monotonic interval model')
    accepted=False
    if len(value['raw'])<=65536 and value['stream_EOF'] and value['elapsed_seconds']<10:
        try:
            envelope=json.loads(value['raw'].decode('utf8'),object_pairs_hook=unique_pairs)
            accepted=(canonical(envelope)==value['raw'] and canonical(envelope)==canonical(FIXTURE_ENVELOPE)
                and value['signature_ok'] and value['independent_launch_origin'])
        except (ValueError,UnicodeError,TypeError):accepted=False
    return dict(model_original_context_eligible=accepted,modeled_grant_reusable=False,modeled_relaunch_authorized=False,
        actual_authentication_proven=False,actual_launch_origin_proven=False,actual_dispatch_authorized=False,
        actual_grant_consumed=False,actual_pipe_or_deadline_proven=False,actual_operational_conformance=False)

def evaluate_private_descriptors(value):
    exact(sorted(value),['descriptors','origin','scope'],'descriptor fields');exact(value['origin'],'synthetic-private-fixture','FD origin')
    exact(value['scope'],'typed-FD-contract-not-real-objects','FD scope')
    rows=value['descriptors']
    if type(rows) is not list or len(rows)>32:raise ValueError('bounded descriptor inventory')
    seen=set();roles=set();accepted=True
    for row in rows:
        exact(sorted(row),['alias_known','fd','kind','lifetime','origin','reviewed','role','service_reachable'],'descriptor row fields')
        if type(row['fd']) is not int or row['fd']<0 or row['fd']>1024:raise ValueError('descriptor number type')
        if any(type(row[k]) is not bool for k in ['reviewed','service_reachable','alias_known']):raise ValueError('typed descriptor facts')
        if any(type(row[k]) is not str for k in ['kind','role','origin','lifetime']):raise ValueError('typed descriptor classification')
        if row['fd'] in seen:accepted=False
        seen.add(row['fd']);valid=row['reviewed'] and row['alias_known'] and not row['service_reachable']
        if row['role'] in ['stdin','stdout','stderr']:
            expected_fd={'stdin':0,'stdout':1,'stderr':2}[row['role']]
            valid=valid and row['fd']==expected_fd and row['kind']=='pipe' and row['origin']=='reviewed-isolated-stream' and row['lifetime']=='bounded-command-stream'
            if row['role'] in roles:valid=False
            roles.add(row['role'])
        elif row['role']=='retained-code':
            valid=valid and row['fd']>2 and row['kind']=='read-only-file' and row['origin']=='reviewed-bound-code-object' and row['lifetime']=='until-reviewed-consumption-then-close-before-unreviewed-helper-dispatch'
        else:valid=False
        accepted=accepted and valid
    accepted=accepted and roles=={'stdin','stdout','stderr'}
    return dict(model_child_FD_set_eligible=accepted,actual_FD_identity_or_alias_proven=False,actual_service_exclusion_proven=False,
        actual_interpreter_lifetime_proven=False,actual_dispatch_authorized=False,actual_operational_conformance=False)

def evaluate_private_command_gate(value):
    exact(sorted(value),['conditions','origin','scope'],'command gate fields');exact(value['origin'],'synthetic-private-fixture','command gate origin')
    exact(value['scope'],'handoff-and-command-contract-only','command gate scope')
    exact(sorted(value['conditions']),sorted(GATE_KEYS),'all independent command conditions')
    if any(type(x) is not bool for x in value['conditions'].values()):raise ValueError('typed command condition')
    return dict(model_command_preparation_eligible=all(value['conditions'].values()),actual_dispatch_authorized=False,
        actual_grant_consumed=False,actual_namespace_created=False,actual_operational_conformance=False,
        actual_host_obligations_closed=False,actual_strong_safe_pause_confirmed=False,retry_authorized=False,recovery_authorized=False)


def run_historical(history):
    with tempfile.TemporaryDirectory(prefix='step321-exact320-') as directory:
        snapshot = Path(directory)/'slack-update'
        for rel,content in history.items():
            p = snapshot/safe_relative(rel); p.parent.mkdir(parents=True,exist_ok=True); p.write_bytes(content)
        result = subprocess.run(['bash',str(snapshot/'tests/reference'/('test-'+PRIOR+'-harness.sh'))],capture_output=True)
        lines = result.stdout.decode().splitlines()
        if result.returncode or lines.count('Result: PASS (843 passes, 0 failures)')!=1 or sum(x.startswith('PASS: ') for x in lines)!=843:
            sys.stderr.buffer.write(result.stdout+result.stderr)
            raise ValueError('full exact843 predecessor acceptance failed')
        return result.stdout

def main(root,out):
    if not root.is_dir() or root.absolute()!=root.resolve():raise ValueError('unsafe repository root')
    for rel,digest in OWN_HASHES.items():exact(sha(safe_file(root,rel)),digest,'changed321 input '+rel)
    fixture=root/FIXTURE;load=lambda suffix:json.loads((fixture/(BASE+suffix)).read_bytes())
    policy,design=load('-policy.json'),load('-design.json');history=verify_history(root,policy)
    frozen=json.loads(history[FIXTURE+'/'+REQUIREMENTS_BASE+'-freeze.json']);prior=json.loads(history[FIXTURE+'/'+PRIOR+'-design.json'])
    validate_design(design,prior,frozen);validate_confirmation(load('-checkpoint-confirmation.json'),load('-step320-user-acceptance.json'))
    validate_tables(*[(fixture/(BASE+s)).read_bytes() for s in ['-descriptor-policy.tsv','-handoff-gates.tsv']])
    payloads={BASE+s:(fixture/(BASE+s)).read_bytes() for s in SUFFIXES};log_name=BASE+'-predecessor-test.log'
    if not out.is_dir() or out.absolute()!=out.resolve():raise ValueError('output must exist without symlink ancestors')
    if any((out/name).exists() or (out/name).is_symlink() for name in list(payloads)+[log_name]):raise ValueError('occupied output; no overwrite')
    payloads[log_name]=run_historical(history);exact(verify_history(root,policy),history,'history changed during validation')
    for rel,digest in OWN_HASHES.items():exact(sha(safe_file(root,rel)),digest,'321 input changed during validation')
    created=[]
    try:
        for name,content in payloads.items():
            with (out/name).open('xb') as stream:created.append(out/name);stream.write(content)
    except BaseException:
        for p in reversed(created):p.unlink()
        raise
    print('exact_step320_acceptance\tPASS (843 passes, 0 failures)')
    print('step321_handoff_design_review_status\tPASS')
    print('selected_handoff_contract\tyes')
    print('actual_dispatch_authorized\tno')
    print('actual_authentication_or_FD_containment_proven\tno')
    print('operational_readiness\tno')
    print('strong_safe_pause\tno')
    print('last_confirmed_strong_safe_pause_step\t318')
    print('next_stage_authorized\tno')

if __name__ == '__main__':
    try: main(Path(sys.argv[1]).absolute(),Path(sys.argv[2]).absolute())
    except (ValueError,OSError,KeyError,TypeError) as exc:
        print('ERROR: '+str(exc),file=sys.stderr);sys.exit(1)
PYREVIEW
