#!/bin/bash
set -euo pipefail
export LC_ALL=C
script_dir=$(CDPATH= cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)
repo_root=$(CDPATH= cd -- "$script_dir/../.." && pwd -P)
if [[ $# -eq 1 && $1 == --help ]]; then
    printf 'Usage: %s --output-dir DIR\nRepository-only reference/selector requirements review; no live authority.\n' "${0##*/}"
    exit 0
fi
[[ $# -eq 2 && $1 == --output-dir && -n $2 ]] || { printf 'ERROR: expected --output-dir DIR\n' >&2; exit 2; }
python3 - "$repo_root" "$2" <<'PYREVIEW'
import ast
import hashlib
import json
import re
import subprocess
import sys
import tempfile
from pathlib import Path

BASE = 'phase-1-kernel-package-edge-runtime-transaction-remediation-local-source-v4-operational-reference-integration-and-selector-requirements-review'
PRIOR = 'phase-1-kernel-package-edge-runtime-transaction-remediation-local-source-v4-runtime-implementation-post-closure-resume-planning-boundary-review'
FIXTURE = 'tests/fixtures/reference/acceptance/phase-1'
BASELINE_DIGEST = 'fee27298a7188ca11872733b29947b33b14a19b49efc7f3ffe6841f0199fd11e'
RECEIPT_DIGEST = 'e47143daf6b76b782fc037877497f400f693a4055c960f51ff2d9029d20ead89'
OWN_HASHES = {'docs/reference/phase-1-kernel-package-edge-runtime-transaction-remediation-local-source-v4-operational-reference-integration-and-selector-requirements-review.md': '6828e47d5fb5caadcce2b712046b17860e2ab526c30ebd5eae733b12db3c9d58', 'tests/fixtures/reference/acceptance/phase-1/phase-1-kernel-package-edge-runtime-transaction-remediation-local-source-v4-operational-reference-integration-and-selector-requirements-review-review.json': '69d846f1a5473cc8e2859ee7f3a242047c32d49e364601f9429054a742cdabf8', 'tests/fixtures/reference/acceptance/phase-1/phase-1-kernel-package-edge-runtime-transaction-remediation-local-source-v4-operational-reference-integration-and-selector-requirements-review-policy.json': '9fcb69804f2d3abff675044f477b903416314bb7a195a938e45b1ee1f1260fa1', 'tests/fixtures/reference/acceptance/phase-1/phase-1-kernel-package-edge-runtime-transaction-remediation-local-source-v4-operational-reference-integration-and-selector-requirements-review-checkpoint-confirmation.json': '5068f8da45b37697b1f83b7701cc9552a7b9c5d31c7da9871a813496e6ca736c', 'tests/fixtures/reference/acceptance/phase-1/phase-1-kernel-package-edge-runtime-transaction-remediation-local-source-v4-operational-reference-integration-and-selector-requirements-review-step309-user-acceptance.json': '5af4bce94683e54e0642d634f1beda576901238b2d7d032bb1644390174faad6', 'tests/fixtures/reference/acceptance/phase-1/phase-1-kernel-package-edge-runtime-transaction-remediation-local-source-v4-operational-reference-integration-and-selector-requirements-review.tsv': 'd28be5ac01c84a65a7e50647ce6feb110b44ff5f788a74c1f1c69e6cc8192f7d', 'tests/fixtures/reference/acceptance/phase-1/phase-1-kernel-package-edge-runtime-transaction-remediation-local-source-v4-operational-reference-integration-and-selector-requirements-review-call-map.tsv': 'ba98d4ae1fdcd8784b08cc4c9b80f11cfeb8790191ba242cd0b91e303e8a54f3', 'tests/fixtures/reference/acceptance/phase-1/phase-1-kernel-package-edge-runtime-transaction-remediation-local-source-v4-operational-reference-integration-and-selector-requirements-review-selector-proof-matrix.tsv': '210ccebea48bafad8b6b3cedb1fe48508c9f3351714f7813bf6bf8ed9f4c46a7'}
CHANGELOG_PREFIX = "## Phase 1 step310 — reference integration and selector requirements review — 2026-10-04\n\n- Confirmed309:59c65ac prefix only, complete280 PASS, application/commit and explicit successful SSH push retry followed by empty short status and matching HEAD/origin. Preserve initial Broken-pipe transport failure; this was not executor/runtime retry. Full ID unknown, no independent host/GitHub inspection.\n- Preserve1359 accepted artifacts and exact CHANGELOG suffix, including immutable prepared309 wording. Add ten review/policy/receipt/table/test artifacts, prepared snapshot1369. Candidate/reference/freeze306/review307/closure308/source/history untouched.\n- Review first capability only: map eighteen exact reference function slices and three nested argv/status calls. Immutable caller records failures and may continue later package calls; future adapter needs a persistent failure latch. Nested update requires unchanged fresh pkglist SHA/stream checks, not silent rebinding.\n- Separate reference raw20 no-op classifier from frozen private emulator's nonzero rejection. Require raw status preservation, reviewed empty install-new0/20 disposition and verified exact-target upgrade0 effect; upgrade20 fails the mandatory one-target contract. Version-specific backend semantics remain unproven.\n- Define complete actual selector vector equivalence, exact backend/config/filter/packageDB provenance, negative filter cases and whole-entry side effects beyond three Slackpkg calls. Actual selector/backend payload absent; equivalence, operational implementation/readiness/conformance false. Six remaining dependencies require separate review.\n- Acceptance statically binds actual bytes and privately executes only the exact pure status helper/update function with explicit file-free injected functions and no command fallback. No top-level/reference main, actual selector/backend/package/config/boot/network command or live observation. These finite slices do not prove whole-reference/live selector behavior.\n- Full280 predecessor acceptance reruns in exact1359 snapshot, recursively preserving324 historical acceptance without patched inputs/constants. New typed requirement/effect/authority/receipt/identity gates and private protocol probes accompany the delivery. Existing authorizations closed, operational bindings/SHA null, v2 never sourced/run.\n- Prepared310 user checkpoint pending. Only namespace/transport/no-fallback review311 after complete user application/tests/commit/push/clean-tree return. Route309–318 unchanged;319–320 reserve unauthorized. No new safe/strong pause, no delivery machine/controller action; historical308 valid, Phase1/kernel-package-edge incomplete, Phase2/production closed.\n\n"
REVIEW_SPEC = {'schema': 1, 'step': 310, 'capability': 'real-reference-integration-and-selector-equivalence', 'scope': 'separate-reference-integration-and-selector-requirements-review-only', 'review_status': 'PASS', 'reviewed_requirements_not_frozen': True, 'reference_path': 'tools/reference/slack-update-reference.sh', 'reference_facts': {'scope': 'bound-static-reference-slices-not-live-backend-selector-proof', 'reference_sha256': '1014658196f384b29756827b9074fb0393aeaaf82dad857ff4da91762d9ca415', 'nested_commands': [{'argv': ['-batch=on', '-default_answer=y', 'update'], 'status_variable': 'SLACKPKG_UPDATE_STATUS', 'failure_handler': 'record-status-and-continue-caller'}, {'argv': ['-batch=on', '-default_answer=y', '-postinst=off', 'install-new'], 'status_variable': 'SLACKPKG_INSTALL_NEW_STATUS', 'failure_handler': 'record-status-and-continue-caller'}, {'argv': ['-batch=on', '-default_answer=y', '-postinst=off', 'upgrade-all'], 'status_variable': 'SLACKPKG_UPGRADE_ALL_STATUS', 'failure_handler': 'record-status-and-continue-caller'}], 'function_slices': {'main': {'start_line': 6558, 'end_line': 6633, 'sha256': 'f130236d36ec27475789b7c65ca252ca33529e91d90f2e3206a9e3fc186980da'}, 'run_apply_workflow': {'start_line': 6301, 'end_line': 6554, 'sha256': '7321a68db95d20700cc79d9c9f8a85f1dcba7dfa5c2667a571c388a8863c5d8f'}, 'update_slackware_system': {'start_line': 3425, 'end_line': 3454, 'sha256': 'f3b69155b700765d5c635c040750787c6c6b574646972a6bab63ed2e29577c6e'}, 'slackpkg_apply_action_failed': {'start_line': 3089, 'end_line': 3107, 'sha256': 'b643fc49a6da72e2e0889e517523cffa1c8e39e5cdd92a40b2bd7f5d4111fde6'}, 'capture_pending_new_config_files': {'start_line': 3402, 'end_line': 3423, 'sha256': '8add925730a17eebe3e9a86cc2d01b27b5176f410391f311bf072b292d4ed5bf'}, 'capture_package_snapshot_before': {'start_line': 3069, 'end_line': 3087, 'sha256': 'daeb1434bbdf708f81c94aad58fd21a6be5709791edfc5a19757ac74b6078791'}, 'capture_package_snapshot_after': {'start_line': 3456, 'end_line': 3474, 'sha256': 'e5ec07c43c2ac4b63f56c22b246209bdb1a77b13d4a21dd000bd4f8914074fb1'}, 'probe_boot_module': {'start_line': 1967, 'end_line': 2026, 'sha256': '6bc0b4d0a8dc32da1aabda0450a583f50bbf96fbe3d3380c85d5e5dbb62610d4'}, 'prepare_geninitrd_grub_policy_override': {'start_line': 3327, 'end_line': 3344, 'sha256': '5f9109e033a2adb05de229f0ee8f880824ed295ac5132bd11665c43e278dae04'}, 'restore_geninitrd_grub_policy_override': {'start_line': 3346, 'end_line': 3400, 'sha256': '700e61fb0dd33ee4808cec5844fff3dd9b4cc1b8fa355fbade3b5bd45bb6bc27'}, 'run_boot_preparation_module': {'start_line': 6233, 'end_line': 6299, 'sha256': 'c2e80dc8b7fa3a9edb2c21a2315d936d94aebf5ca5ed009e07f485353455dc63'}, 'initialize_runtime': {'start_line': 2293, 'end_line': 2345, 'sha256': '7fa4c842ba1ca42c563c4d5e548289b61e36c75d435a35707ed947cc576b6a68'}, 'acquire_instance_lock': {'start_line': 2121, 'end_line': 2140, 'sha256': 'ece5bbeba936abd074563740080b312f11064a3b2e2f856222ca2ced2aaee6f7'}, 'install_runtime_traps': {'start_line': 2464, 'end_line': 2469, 'sha256': '475b8fe578f752d9f7d0eb193ca273c02e827e92d0be7c223c599fe5f64f4105'}, 'load_configuration': {'start_line': 590, 'end_line': 596, 'sha256': '7c5898954e383019a5364eda92af1cc8657912c632f6f62fe5323d8333c0d5d2'}, 'parse_arguments': {'start_line': 95, 'end_line': 148, 'sha256': '5ad8c5a3d97d73de16c631e343eee9284dbc52f3a9d17d80a8872c0848833dba'}, 'determine_stable_exit_code': {'start_line': 5791, 'end_line': 5819, 'sha256': 'c3edf7367fb6650141d8d061d8f4b92410dc1320f91288312b136aba775e2e72'}, 'print_json_result': {'start_line': 6193, 'end_line': 6229, 'sha256': 'bcb0e5dc2067d6a0a8bd88e61a031457d5fef528b549b2e4b5ccbde9669be944'}}, 'coordinator_side_effect_order': ['capture_package_snapshot_before', 'probe_boot_module', 'prepare_geninitrd_grub_policy_override', 'update_slackware_system', 'restore_geninitrd_grub_policy_override', 'capture_package_snapshot_after', 'run_boot_preparation_module'], 'caller_does_not_abort_after_nested_command_failure': True, 'selector_delegated_to_slackpkg': True, 'raw_status20_accepted_for_install_new_and_upgrade_all': True, 'raw_status_minus1_classified_as_unattempted': True, 'reference_has_other_apply_effects_than_three_slackpkg_commands': True, 'reference_own_lock_is_not_platform_writer_exclusion': True}, 'other_deferred_capabilities': ['namespace-command-transport-and-no-fallback', 'absolute-backend-path-and-SHA', 'reviewed-platform-writer-serialization', 'fresh-single-use-grant-source-target-predecessor-and-boot', 'real-source-and-archive-revalidation', 'operational-owner-and-publication-path-bindings'], 'candidate_sha256_bindings': {'tests/reference/test-phase-1-kernel-package-edge-runtime-transaction-remediation-local-source-v4-runtime-executor-failure-coverage-review-private.py': '04782004cb683563a9a7ca8522d808686db359f7117e0c9355de189b088c39a4', 'tools/reference/phase-1-kernel-package-edge-runtime-transaction-remediation-local-source-v4-runtime-executor-failure-coverage-candidate-private.py': '9c6bf6d82a15eef3eb74ae8e3aa7ccfbff46af07ec0c105f6c2db4fa5402d7e4', 'tools/reference/phase-1-kernel-package-edge-runtime-transaction-remediation-local-source-v4-runtime-executor-failure-coverage-candidate.sh': 'd861b551c1197b3d83c3535741d8cca5011294b5ea0c8a27d80fd686aa489939'}, 'mandatory_private_tests': ['each-stage-failure', 'catchable-signals', 'uncatchable-loss-null-status', 'cleanup-idempotence', 'cleanup-failure-original-status', 'failed-backup-before-production-write', 'nested-reference-refresh-pkglist-drift', 'adapter-unknown-argv', 'publication-partial-receipt', 'source-and-history-preservation'], 'proof_state': {'requirements_review_complete': True, 'bound_static_call_mapping': True, 'exact_pure_status_helper_private_probe_required': True, 'exact_update_function_file_free_injection_probe_required': True, 'real_reference_main_entered': False, 'actual_slackpkg_selector_executed': False, 'actual_selector_equivalence_proven': False, 'operational_capability_complete': False, 'operational_readiness': False, 'operational_conformance': False, 'production_entry_closed': True}, 'findings': [{'id': 'caller-continuation', 'fact': 'update_slackware_system records nonzero raw status and may continue install-new and upgrade-all before coordinator classification', 'consequence': 'adapter must latch failure for the entire reference invocation and reject all later mutations even if caller continues'}, {'id': 'nested-refresh', 'fact': 'reference apply performs its own update after executor initial refresh and candidate binding', 'consequence': 'revalidate streams fresh regular pkglist and identical binding after nested update; never silently rebind changed candidates'}, {'id': 'selector-delegation', 'fact': 'immutable update function invokes slackpkg; private eight-field oracle does not execute actual backend selector', 'consequence': 'real selector equivalence remains unproven until versioned backend selector/filter/DB identities and complete selected vectors are reviewed'}, {'id': 'raw-status20', 'fact': 'reference predicate accepts20 for both install-new and upgrade-all while frozen private emulator rejects nonzero nested backend exit', 'consequence': 'preserve all raw exits; require reviewed empty-install-new0-or20 disposition and fail upgrade20 under mandatory single-target-effect contract; separate version-specific real backend proof still required'}, {'id': 'whole-entry-effects', 'fact': 'main and coordinator acquire lock initialize runtime logs capture snapshots prepare/restore GenInitrd policy and later boot workflow', 'consequence': 'three guarded slackpkg calls alone do not isolate whole reference; outer guards child supervision namespace writers ownership and every reachable effect require separate review before main'}, {'id': 'scope-of-slices', 'fact': 'private probes execute only exact bound pure status helper and update body with file-free explicit injected functions', 'consequence': 'these finite probes establish caller policy and continuation only; no real selector backend whole-entry or platform conformance claim'}], 'adapter_requirements': {'exact_argv_allowlist': [{'argv': ['-batch=on', '-default_answer=y', 'update'], 'status_variable': 'SLACKPKG_UPDATE_STATUS', 'failure_handler': 'record-status-and-continue-caller'}, {'argv': ['-batch=on', '-default_answer=y', '-postinst=off', 'install-new'], 'status_variable': 'SLACKPKG_INSTALL_NEW_STATUS', 'failure_handler': 'record-status-and-continue-caller'}, {'argv': ['-batch=on', '-default_answer=y', '-postinst=off', 'upgrade-all'], 'status_variable': 'SLACKPKG_UPGRADE_ALL_STATUS', 'failure_handler': 'record-status-and-continue-caller'}], 'persistent_failure_latch_before_backend_dispatch': True, 'later_mutating_calls_rejected_after_any_latched_failure': True, 'raw_nested_status_never_normalized': True, 'backend_resolution_absolute_canonical_SHA_no_PATH_recursion': True, 'unknown_argv_or_missing_binding_rejects_before_backend': True, 'before_each_nested_call_require_fresh_grant_boot_source_target_predecessor_and_pkglist': True, 'nested_update_exit0_and_both_stream_error_guard_and_unchanged_regular_pkglist_SHA': True, 'install_new_expected_candidates': 0, 'install_new_status_policy': 'raw0-or20-only-with-proven-empty-selector-and-no-effects-version-specific-backend-proof-required', 'upgrade_all_expected_candidates': 1, 'upgrade_all_status_policy': 'raw0-and-verified-exact-target-effect-required-raw20-rejects-single-target-contract', 'candidate_drift_must_stop_not_rebind': True, 'streams_exit_signal_and_child_quiescence_evidence_required': True, 'implementation_status': 'requirements-only-not-implemented'}, 'selector_equivalence_requirements': {'actual_backend_selector_path': None, 'actual_backend_selector_sha256': None, 'actual_backend_version': None, 'actual_selector_config_filter_and_packageDB_bindings': None, 'actual_selected_install_new_vector': None, 'actual_selected_upgrade_all_vector': None, 'exact_complete_vectors_not_counts_only': True, 'pkglist_single_row_is_not_actual_selector_proof': True, 'reference_dry_run_or_json_is_not_backend_selector_enumeration': True, 'oracle_inputs_and_actual_selector_inputs_must_be_identical': True, 'compatibility_targets': ['Slackware-15.0', 'Slackware-current'], 'compatibility_evidence_separate_per_bound_backend': True, 'permission_to_collect_or_execute_backend_selector': False}, 'selector_proof_obligations': [{'id': 'immutable-reference-and-config', 'required_evidence': 'exact-reviewed-reference-config-SHA-and-canonical-payload-paths', 'scope': 'future-operational-integration', 'status': 'required-not-live-bound'}, {'id': 'actual-selector-provenance', 'required_evidence': 'versioned-slackpkg-selector-source-config-filters-and-installed-DB-identities-for15-and-current', 'scope': 'future-actual-selector-conformance', 'status': 'blocked-actual-backend-payload-absent'}, {'id': 'selection-vector-equivalence', 'required_evidence': 'actual-install-new-empty-and-upgrade-all-one-exact-target-vectors-equal-reviewed-oracle-under-identical-inputs', 'scope': 'future-actual-selector-conformance', 'status': 'required-not-proven'}, {'id': 'selector-filter-negative-cases', 'required_evidence': 'blacklist-priority-repository-architecture-installed-version-duplicate-and-foreign-candidate-exclusion-cases', 'scope': 'future-actual-selector-conformance', 'status': 'required-not-proven'}, {'id': 'nested-refresh-latch', 'required_evidence': 'exit-stream-error-regular-pkglist-and-bound-SHA-recheck-after-nested-update-failure-latches-before-later-call', 'scope': 'future-guarded-adapter-integration', 'status': 'required-not-implemented'}, {'id': 'exact-caller-protocol', 'required_evidence': 'three-exact-argv-calls-and-caller-continuation-after-failure-in-bound-update-function-slice', 'scope': 'private-file-free-reference-slice', 'status': 'finite-private-proof-required-by-current-harness'}, {'id': 'raw-noop-status', 'required_evidence': 'preserve-raw20-install-new-empty-policy-and-reject-upgrade20-when-one-target-effect-required-no-normalization', 'scope': 'future-backend-disposition-and-private-helper-policy', 'status': 'private-policy-proof-only-real-backend-disposition-pending'}, {'id': 'whole-reference-effect-admission', 'required_evidence': 'outer-guards-before-main-and-all-lock-runtime-snapshot-GenInitrd-log-boot-effects-owned-or-rejected', 'scope': 'future-whole-reference-integration', 'status': 'required-not-live-proven'}, {'id': 'missing-guard-no-fallback', 'required_evidence': 'unknown-argv-unbound-backend-or-missing-six-capabilities-fails-before-any-real-entry-or-mutation', 'scope': 'future-integration-admission', 'status': 'required-not-operationally-implemented'}, {'id': 'same-transaction-revalidation', 'required_evidence': 'new-single-use-grant-source-target-predecessor-boot-and-selector-input-SHA-before-each-call', 'scope': 'future-fresh-operational-authorization', 'status': 'required-not-live-bound'}, {'id': 'effect-and-restoration-conformance', 'required_evidence': 'actual-one-target-package-effect-no-foreign-boot-effects-and-verified-full-baseline-restoration', 'scope': 'future-real-isolated-transaction', 'status': 'required-not-run'}, {'id': 'evidence-children-and-publication', 'required_evidence': 'distinct-nested-streams-raw-exits-latched-original-failure-owned-child-wait-drain-and-last-receipt', 'scope': 'future-integrated-failure-conformance', 'status': 'required-not-live-proven'}], 'permitted_current_effects': ['repository-review-metadata-and-private-temp-evidence', 'bound-function-static-inspection', 'exact-pure-helper-and-file-free-update-slice-probes'], 'prohibited_current_effects': ['whole-reference-source-or-main-entry', 'real-slackpkg-selector-or-package-command', 'host-package-config-boot-write', 'network-or-transport', 'old-v2-source-or-run', 'grant-issuance-or-live-binding-reuse', 'cleanup-of-source-history-or-live-state'], 'blockers': ['actual-selector-backend-source-and-filter-identities-unavailable', 'six-other-operational-capabilities-require-separate-reviews', 'guarded-adapter-and-whole-entry-admission-not-implemented', 'version-specific-selector-and-raw-status-disposition-conformance-not-executed']}
FUNCTION_NAMES = ['main', 'run_apply_workflow', 'update_slackware_system', 'slackpkg_apply_action_failed', 'capture_pending_new_config_files', 'capture_package_snapshot_before', 'capture_package_snapshot_after', 'probe_boot_module', 'prepare_geninitrd_grub_policy_override', 'restore_geninitrd_grub_policy_override', 'run_boot_preparation_module', 'initialize_runtime', 'acquire_instance_lock', 'install_runtime_traps', 'load_configuration', 'parse_arguments', 'determine_stable_exit_code', 'print_json_result']
PLAN_KEYS = ['accepted_checkpoint', 'actual_reference_main_entered', 'actual_selector_equivalence_proven', 'actual_slackpkg_selector_executed', 'authorization', 'capability', 'confirmed309_supersedes_immutable_prepared_wording', 'controller_action_required', 'fresh_boundary', 'frozen_private_scope', 'historical_step308_pause_remains_valid', 'historical_v2_sourced_or_run', 'kernel_package_edge_complete', 'machine_action_required', 'new_repository_artifact_count', 'next_stage', 'next_stage_authorized', 'next_stage_condition', 'operational_capability_complete', 'operational_conformance', 'operational_executor_sha256', 'operational_implementation_complete', 'operational_readiness', 'other_deferred_capabilities', 'pause_safe', 'phase1_matrix_complete', 'phase2_open', 'prepared_repository_file_count', 'private_probe_scope', 'production_entry_closed', 'repository_stage_permission', 'requirements_review_complete', 'review_only', 'review_path', 'review_sha256', 'review_status', 'roadmap', 'runtime_attempt_planned', 'scenario', 'schema', 'state', 'step', 'strong_pause_completion_conditions', 'strong_safe_pause', 'user_step310_checkpoint_confirmed']

def exact(actual, expected, label):
    if isinstance(actual, set) and isinstance(expected, set):
        actual, expected = sorted(actual), sorted(expected)
    if json.dumps(actual, sort_keys=True) != json.dumps(expected, sort_keys=True):
        raise ValueError(label)

def sha(content):
    return hashlib.sha256(content).hexdigest()

def safe_relative(rel):
    if not isinstance(rel, str) or not rel or '\\' in rel:
        raise ValueError('unsafe relative path')
    path = Path(rel)
    if path.is_absolute() or any(part in ('', '.', '..') for part in rel.split('/')):
        raise ValueError('unsafe relative path')
    return path

def safe_regular(path, root):
    return (path.is_file() and not path.is_symlink()
            and path.absolute() == path.resolve()
            and path.resolve().is_relative_to(root.resolve()))

def verify_history(root, accepted, changelog_prefix):
    history = {}
    for rel, digest in accepted['sha256_bindings'].items():
        path = root / safe_relative(rel)
        if not safe_regular(path, root):
            raise ValueError('missing or unsafe accepted artifact: ' + rel)
        content = path.read_bytes()
        if rel == 'CHANGELOG.md':
            size = accepted['changelog_size_bytes']
            if len(content) != size + len(changelog_prefix):
                raise ValueError('unexpected CHANGELOG prefix or suffix length')
            if content[:len(changelog_prefix)] != changelog_prefix:
                raise ValueError('changed step309 CHANGELOG prefix')
            content = content[len(changelog_prefix):]
        if sha(content) != digest:
            raise ValueError('accepted SHA mismatch: ' + rel)
        history[rel] = content
    return history

def publish_outputs(out, payloads):
    if not out.is_dir() or out.absolute() != out.resolve():
        raise ValueError('output directory must exist without symlink ancestors')
    for name in payloads:
        safe_relative(name)
        if (out / name).exists() or (out / name).is_symlink():
            raise ValueError('occupied planning output: ' + name)
    created = []
    try:
        for name, content in payloads.items():
            with (out / name).open('xb') as handle:
                created.append(out / name)
                handle.write(content)
    except BaseException:
        for path in reversed(created):
            path.unlink()
        raise


def extract_functions(raw, names):
    # Exact bound shell slices only; this is not a general Bash grammar parser.
    lines = raw.decode('utf-8').splitlines(keepends=True)
    result = {}
    for name in names:
        matches = [i for i, line in enumerate(lines) if line == name + '() {\n']
        if len(matches) != 1:
            raise ValueError('nonunique reference function: ' + name)
        start = matches[0]
        ends = [i for i in range(start + 1, len(lines)) if lines[i] == '}\n']
        if not ends:
            raise ValueError('unterminated bound function slice: ' + name)
        end = ends[0]
        content = ''.join(lines[start:end + 1]).encode()
        result[name] = dict(start_line=start + 1, end_line=end + 1,
            sha256=sha(content), content=content.decode())
    return result


def extract_reference_facts(raw):
    functions = extract_functions(raw, FUNCTION_NAMES)
    update = functions['update_slackware_system']['content']
    argv = []
    for line in update.splitlines():
        match = re.fullmatch(r'\s*slackpkg (.+?) \|\| (SLACKPKG_[A-Z_]+)=\$\?\s*', line)
        if match:
            argv.append(dict(argv=match[1].split(), status_variable=match[2],
                failure_handler='record-status-and-continue-caller'))
    expected = [dict(argv=['-batch=on', '-default_answer=y', 'update'], status_variable='SLACKPKG_UPDATE_STATUS', failure_handler='record-status-and-continue-caller'),
        dict(argv=['-batch=on', '-default_answer=y', '-postinst=off', 'install-new'], status_variable='SLACKPKG_INSTALL_NEW_STATUS', failure_handler='record-status-and-continue-caller'),
        dict(argv=['-batch=on', '-default_answer=y', '-postinst=off', 'upgrade-all'], status_variable='SLACKPKG_UPGRADE_ALL_STATUS', failure_handler='record-status-and-continue-caller')]
    exact(argv, expected, 'immutable nested command mapping')
    coordinator = functions['run_apply_workflow']['content']
    ordered = ['capture_package_snapshot_before', 'probe_boot_module',
        'prepare_geninitrd_grub_policy_override', 'update_slackware_system',
        'restore_geninitrd_grub_policy_override', 'capture_package_snapshot_after',
        'run_boot_preparation_module']
    positions = [coordinator.find(name) for name in ordered]
    if any(value < 0 for value in positions) or positions != sorted(positions):
        raise ValueError('coordinator side-effect order drift')
    if any(token in update for token in ['pkglist', 'sha256sum', 'Error downloading from']):
        raise ValueError('unexpected local selector or nested hash/error gate')
    classification = functions['slackpkg_apply_action_failed']['content']
    if 'update:0|install-new:0|install-new:20|upgrade-all:0|upgrade-all:20)' not in classification or '*:-1)' not in classification:
        raise ValueError('reference raw status policy drift')
    entry = functions['main']['content']
    if entry.find('acquire_instance_lock') >= entry.find('install_runtime_traps'):
        raise ValueError('reference lock/trap boundary drift')
    return dict(scope='bound-static-reference-slices-not-live-backend-selector-proof',
        reference_sha256=sha(raw), nested_commands=argv,
        function_slices={name: {k: v for k, v in record.items() if k != 'content'} for name, record in functions.items()},
        coordinator_side_effect_order=ordered,
        caller_does_not_abort_after_nested_command_failure=True,
        selector_delegated_to_slackpkg=True,
        raw_status20_accepted_for_install_new_and_upgrade_all=True,
        raw_status_minus1_classified_as_unattempted=True,
        reference_has_other_apply_effects_than_three_slackpkg_commands=True,
        reference_own_lock_is_not_platform_writer_exclusion=True)


def validate_confirmation(confirmation, receipt):
    for key, value in dict(schema=1, step=309, state='confirmed-step309-repository-resume-checkpoint',
        commit_prefix='59c65ac', commit_full=None, acceptance_result='PASS (280 passes, 0 failures)',
        repository_file_count=1359, user_application_completed=True, user_harness_completed=True,
        user_commit_and_push_completed=True, user_worktree_clean=True,
        user_head_matches_origin=True, initial_push_failed_at_ssh_transport=True,
        explicit_push_retry_succeeded=True, push_first_attempt_succeeded=False,
        push_retry_required=False, runtime_retry_performed=False,
        confirmation_external_to_immutable_repository=True,
        operational_authority_inherited=False, live_target_observed=False,
        user_step309_strong_pause_claimed=False, historical_step308_pause_remains_valid=True,
        scope='complete-original-user-return-not-independent-user-host-or-GitHub-inspection',
        evidence_sha256=RECEIPT_DIGEST, evidence_size_bytes=27770).items():
        exact(confirmation.get(key), value, 'checkpoint309 ' + key)
    exact(receipt.get('encoding'), 'utf8-json-text', 'original receipt encoding')
    text = receipt.get('text')
    if not isinstance(text, str):
        raise ValueError('missing original309 return')
    exact(sha(text.encode()), RECEIPT_DIGEST, 'original309 receipt SHA')
    exact(len(text.encode()), 27770, 'original309 receipt size')
    exact(receipt.get('original_display_sha256'), RECEIPT_DIGEST, 'receipt SHA metadata')
    exact(receipt.get('original_display_size_bytes'), 27770, 'receipt size metadata')
    lines = text.splitlines()
    exact(sum(line.startswith('PASS: ') for line in lines), 280, 'full original280 sequence')
    exact(lines.count('Result: PASS (280 passes, 0 failures)'), 1, 'complete original280 summary')
    if '[main 59c65ac]' not in text or 'Broken pipe' not in text or 'dd0f21e..59c65ac  main -> main' not in text:
        raise ValueError('original commit or separate successful SSH retry missing')
    matching = '59c65ac (HEAD -> main, origin/main, origin/HEAD) Phase 1 step 309: review post-private-closure resume planning boundary'
    exact(lines.count(matching), 2, 'original matching HEAD and origin returns')
    return True


def validate_review(review, facts, prior_plan):
    exact(review, REVIEW_SPEC, 'changed reference/selector requirements specification')
    exact(review['reference_facts'], facts, 'actual immutable reference differs from review')
    exact(review['capability'], prior_plan['deferred_capabilities'][0], 'wrong separate capability')
    exact(review['other_deferred_capabilities'], prior_plan['deferred_capabilities'][1:], 'other six reviews merged or lost')
    if review['proof_state']['actual_selector_equivalence_proven'] or review['proof_state']['operational_capability_complete']:
        raise ValueError('requirements review cannot complete operational capability')
    return True


def validate_policy(policy, confirmation, receipt, prior_plan, review):
    validate_confirmation(confirmation, receipt)
    exact(sorted(policy), PLAN_KEYS, 'unknown/missing310 policy fields')
    for key, value in dict(schema=1, step=310, scenario=BASE, review_status='PASS', review_only=True,
        state='requirements-review-prepared-user-checkpoint-pending',
        user_step310_checkpoint_confirmed=False, pause_safe=False, strong_safe_pause=False,
        machine_action_required=False, controller_action_required=False,
        runtime_attempt_planned=False, phase1_matrix_complete=False,
        kernel_package_edge_complete=False, phase2_open=False, production_entry_closed=True,
        operational_readiness=False, operational_implementation_complete=False,
        operational_conformance=False, operational_executor_sha256=None,
        actual_reference_main_entered=False, actual_slackpkg_selector_executed=False,
        requirements_review_complete=True, operational_capability_complete=False,
        actual_selector_equivalence_proven=False, historical_v2_sourced_or_run=False,
        historical_step308_pause_remains_valid=True,
        confirmed309_supersedes_immutable_prepared_wording=True,
        new_repository_artifact_count=10, prepared_repository_file_count=1369,
        next_stage=prior_plan['roadmap']['preferred_steps'][2]['stage'], next_stage_authorized=False,
        next_stage_condition='complete-user310-application-current-tests-commit-push-clean-tree-return').items():
        exact(policy.get(key), value, '310 policy boundary ' + key)
    exact(policy['authorization'], prior_plan['authorization'], 'old authority must stay closed')
    exact(policy['fresh_boundary'], prior_plan['fresh_boundary'], 'new operational binding forbidden')
    exact(policy['frozen_private_scope'], prior_plan['frozen_private_scope'], 'private mandatory scope changed')
    exact(policy['roadmap'], prior_plan['roadmap'], 'accepted309 route changed')
    exact(policy['capability'], prior_plan['deferred_capabilities'][0], 'capability identity')
    exact(policy['other_deferred_capabilities'], prior_plan['deferred_capabilities'][1:], 'six separate pending components')
    exact(policy['strong_pause_completion_conditions'], prior_plan['strong_pause_completion_conditions'], 'weakened final pause conditions')
    exact(policy['repository_stage_permission'], dict(current_scope='separate-reference-selector-requirements-review310-only',
        predecessor_permission_consumed_from_confirmed309=True, next_review_step=311,
        next_review_authorized_now=False, requires_complete_user310_checkpoint=True,
        other_capabilities_reviewed_by310=False, later_stages_granted_by_roadmap=False), '310 stage permission gate')
    accepted = policy['accepted_checkpoint']
    for key, value in dict(step=309, commit_prefix='59c65ac', commit_full=None,
        repository_file_count=1359, acceptance_result='PASS (280 passes, 0 failures)',
        provenance='complete-original-user-return-not-independent-user-host-or-GitHub-inspection').items():
        exact(accepted.get(key), value, 'accepted309 checkpoint ' + key)
    if type(accepted['changelog_size_bytes']) is not int or accepted['changelog_size_bytes'] <= 0:
        raise ValueError('invalid accepted CHANGELOG size')
    if not isinstance(accepted['sha256_bindings'], dict) or len(accepted['sha256_bindings']) != 1359:
        raise ValueError('incomplete1359 manifest')
    exact(sha(json.dumps(accepted['sha256_bindings'], sort_keys=True).encode()), BASELINE_DIGEST, 'accepted309 manifest')
    exact(policy['review_path'], FIXTURE + '/' + BASE + '-review.json', 'review path')
    exact(policy['review_sha256'], sha((json.dumps(review, indent=2, sort_keys=True) + '\n').encode()), 'raw review SHA')
    exact(policy['private_probe_scope'], dict(exact_update_function_slice_with_file_free_injected_functions=True,
        exact_pure_status_helper_slice=True, reference_top_level_sourced=False,
        reference_main_entered=False, real_slackpkg_executed=False,
        actual_selector_equivalence_proven=False, host_package_config_boot_writes=False,
        no_external_command_fallback=True), 'private source-slice proof scope')
    return True


def validate_tables(record, call_map, matrix, review, policy):
    rows = record.decode().splitlines()
    if any(line.count('\t') != 1 for line in rows) or len({line.split('\t')[0] for line in rows}) != len(rows):
        raise ValueError('invalid record TSV')
    exact(dict(line.split('\t') for line in rows), dict(step='310', requirements_review_status='PASS',
        accepted_checkpoint_commit='59c65ac', accepted_checkpoint_acceptance='PASS (280 passes, 0 failures)',
        initial_push_transport_failure='preserved', explicit_push_retry_succeeded='yes',
        requirements_review_complete='yes', actual_selector_equivalence_proven='no',
        operational_capability_complete='no', operational_readiness='no', operational_conformance='no',
        production_entry_closed='yes', operational_executor_sha256='null',
        runtime_attempt_authorized='no', user_step310_checkpoint_confirmed='no',
        machine_action_required='no', controller_action_required='no', pause_safe='no', strong_safe_pause='no',
        next_stage_authorized='no', next_stage=policy['next_stage']), 'typed requirement record')
    expected = ['order\targv\tstatus_variable\tcaller_failure_handler']
    for i, row in enumerate(review['reference_facts']['nested_commands']):
        expected.append('\t'.join([str(i), ' '.join(row['argv']), row['status_variable'], row['failure_handler']]))
    exact(call_map.decode().splitlines(), expected, 'actual reference call-map TSV')
    expected = ['id\trequired_evidence\tscope\tstatus']
    expected += ['\t'.join([row['id'], row['required_evidence'], row['scope'], row['status']])
                 for row in review['selector_proof_obligations']]
    exact(matrix.decode().splitlines(), expected, 'selector proof matrix TSV')


def run_historical(history):
    with tempfile.TemporaryDirectory(prefix='step310-exact309-') as directory:
        snapshot = Path(directory) / 'slack-update'
        for rel, content in history.items():
            path = snapshot / safe_relative(rel)
            path.parent.mkdir(parents=True, exist_ok=True)
            path.write_bytes(content)
        result = subprocess.run(['bash', str(snapshot / 'tests/reference' / ('test-' + PRIOR + '-harness.sh'))], capture_output=True, text=True)
        if result.returncode or result.stdout.splitlines().count('Result: PASS (280 passes, 0 failures)') != 1:
            sys.stderr.write(result.stdout + result.stderr)
            raise ValueError('exact full280 predecessor acceptance failed')
        return result.stdout.encode()


def main(root, out):
    if not root.is_dir() or root.absolute() != root.resolve():
        raise ValueError('unsafe repository root')
    for rel, digest in OWN_HASHES.items():
        path = root / safe_relative(rel)
        if not safe_regular(path, root) or sha(path.read_bytes()) != digest:
            raise ValueError('changed or unsafe310 input: ' + rel)
    fixture = root / FIXTURE
    policy = json.loads((fixture / (BASE + '-policy.json')).read_text())
    review = json.loads((fixture / (BASE + '-review.json')).read_text())
    confirmation = json.loads((fixture / (BASE + '-checkpoint-confirmation.json')).read_text())
    receipt = json.loads((fixture / (BASE + '-step309-user-acceptance.json')).read_text())
    history = verify_history(root, policy['accepted_checkpoint'], CHANGELOG_PREFIX.encode())
    prior_plan = json.loads(history[FIXTURE + '/' + PRIOR + '-policy.json'])
    facts = extract_reference_facts(history['tools/reference/slack-update-reference.sh'])
    validate_review(review, facts, prior_plan)
    validate_policy(policy, confirmation, receipt, prior_plan, review)
    validate_tables((fixture / (BASE + '.tsv')).read_bytes(), (fixture / (BASE + '-call-map.tsv')).read_bytes(),
                    (fixture / (BASE + '-selector-proof-matrix.tsv')).read_bytes(), review, policy)
    suffixes = ['-policy.json', '-review.json', '-checkpoint-confirmation.json',
        '-step309-user-acceptance.json', '.tsv', '-call-map.tsv', '-selector-proof-matrix.tsv']
    payloads = {BASE + suffix: (fixture / (BASE + suffix)).read_bytes() for suffix in suffixes}
    if not out.is_dir() or out.absolute() != out.resolve():
        raise ValueError('unsafe review output directory')
    if any((out / name).exists() or (out / name).is_symlink() for name in list(payloads) + [BASE + '-predecessor-test.log']):
        raise ValueError('review outputs must be absent')
    payloads[BASE + '-predecessor-test.log'] = run_historical(history)
    verify_history(root, policy['accepted_checkpoint'], CHANGELOG_PREFIX.encode())
    for rel, digest in OWN_HASHES.items():
        if not safe_regular(root / rel, root) or sha((root / rel).read_bytes()) != digest:
            raise ValueError('310 input changed during historical acceptance')
    publish_outputs(out, payloads)
    for key, value in dict(step310_requirements_review_status='PASS',
        exact_step309_acceptance='PASS (280 passes, 0 failures)',
        requirements_review_complete='yes', actual_selector_equivalence_proven='no',
        operational_capability_complete='no', production_entry_closed='yes',
        user_step310_checkpoint_pending='yes', next_stage_authorized='no',
        machine_action_required='no', controller_action_required='no',
        pause_safe='no', strong_safe_pause='no', next_stage=policy['next_stage']).items():
        print(key + '\t' + value)


if __name__ == '__main__':
    try:
        main(Path(sys.argv[1]), Path(sys.argv[2]).absolute())
    except (ValueError, KeyError, TypeError, OSError, json.JSONDecodeError) as error:
        raise SystemExit('ERROR: ' + str(error))
PYREVIEW
