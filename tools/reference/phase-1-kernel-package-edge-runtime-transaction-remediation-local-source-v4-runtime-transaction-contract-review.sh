#!/bin/bash
set -euo pipefail
export LC_ALL=C
script_dir=$(CDPATH= cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)
repo_root=$(CDPATH= cd -- "$script_dir/../.." && pwd -P)
if [[ $# -eq 1 && $1 == --help ]]; then printf 'Usage: %s --output-dir DIR\nRepository-only transaction contract review.\n' "${0##*/}"; exit 0; fi
[[ $# -eq 2 && $1 == --output-dir && -n $2 ]] || { printf 'ERROR: expected --output-dir DIR\n' >&2; exit 2; }
python3 - "$repo_root" "$2" <<'PYREVIEW'
from pathlib import Path
import ast
import hashlib
import json
import re
import subprocess
import sys
import tempfile

def validate_transaction_contract(contract):
    expected = {'schema': 1, 'step': 300, 'state': 'transaction-contract-reviewed-not-frozen-not-implemented-not-authorized', 'scope': 'repository-only-future-transaction-and-restoration-contract', 'frozen_source_candidate_executor': {'accepted_observation_authority_closure': {'additional_target_observation_authorized': False, 'all_operational_authority_closed': True, 'authority_id': 'phase1-step294-post-v4-build-read-only-observation-once', 'controller_capture_preserved_no_cleanup_authorized': True, 'controller_release_issued': True, 'current_boot_continuity_asserted': False, 'effect_review_scope': 'complete-user-returned-no-effect-fields-and-reviewed-read-only-source-not-independent-post-return-host-inspection', 'no_required_production_cleanup_identified': True, 'no_runtime_authority_from_success': True, 'observation_success_accepted': True, 'original_grant_unchanged_as_historical_input': True, 'probe_execution_authority_consumed': True, 'probe_transport_authority_revoked': True, 'remaining_observation_authority_revoked': True, 'retry_authorized': False, 'reviewed_invocation_count': 1, 'state': 'one-observation-consumed-remaining-transport-and-operational-authority-revoked-after-return-review'}, 'candidate': {'all_nonblank_rows_must_match_exact_safe_target_fields': True, 'archive_sha256_reverified_before_binding_and_apply': True, 'binding_lifetime': 'same-future-runtime-transaction-only', 'configured_boot_upgrade_candidate_count': 0, 'current_binding_created': False, 'current_candidate_count': None, 'current_pkglist_path': None, 'current_pkglist_sha256': None, 'empty_historical_v2_pkglist_must_not_be_reused': True, 'error_signal_case_insensitive': True, 'exact_target_candidate_count': 1, 'expected_target_artifact': 'kernel-headers-6.18.45-x86-1.txz', 'expected_target_fields': ['slackware64', 'kernel-headers', '6.18.45', 'x86', '1', 'kernel-headers-6.18.45-x86-1', './slackware64/d', 'txz'], 'expected_target_sha256': 'c7b56b50f0abdec8f35628d526bb05488c257f667ab9c2be1a7a3e07d97da63c', 'install_new_candidate_count': 0, 'metadata_formatter_remediation_is_not_runtime_generation_proof': True, 'missing_duplicate_extra_malformed_or_traversal_rows_rejected': True, 'no_hyphenated_error_literal_substitution': True, 'non_header_upgrade_candidate_count': 0, 'observed_v4_pkglist_generation_success': False, 'pkglist_absent_before_refresh_required': True, 'pkglist_generated_fresh_in_same_transaction_required': True, 'pkglist_nonempty_required': True, 'pkglist_regular_non_symlink_after_refresh_required': True, 'pkglist_sha256_bound_before_apply_required': True, 'refresh_exit0_is_not_sufficient': True, 'refresh_exit0_required': True, 'row_field_names': ['priority_tree', 'name', 'version', 'arch', 'build', 'fullname', 'location', 'extension'], 'state': 'future-same-transaction-binding-required-not-observed', 'stdout_and_stderr_error_signal': 'Error downloading from ', 'transaction_owned_workdir_and_temp_required': True, 'unexpected_header_candidate_count': 0}, 'controller_action_required': False, 'current_operational_authority_closed': True, 'executor': {'accepted_baseline_header_to_restore': 'kernel-headers-6.18.45-x86-1', 'all_v4_and_preserved_target_guards_must_be_repeated': True, 'boot_drift_stops_no_uuid_substitution': True, 'cleanup_trap_required_before_first_mutation': True, 'complete_stage_stdout_stderr_exit_and_cleanup_evidence_required': True, 'consumed_step294_authority_reusable': False, 'fresh_target_and_source_revalidation_required_before_future_authorization': True, 'future_executor_design_implementation_authorized': False, 'future_executor_execution_authorized': False, 'future_executor_installed': False, 'future_executor_path': 'tools/reference/phase-1-kernel-package-edge-runtime-transaction-remediation-local-source-v4-runtime-executor.sh', 'future_executor_sha256': None, 'future_executor_transport_authorized': False, 'historical_boot_argument': '047e744d-d2ea-4d9a-8746-7734b58db3b2', 'historical_executor_is_design_input_only': True, 'historical_executor_path': 'tools/reference/phase-1-kernel-package-edge-runtime-transaction-remediation-v2-executor.sh', 'historical_executor_rerun_authorized': False, 'historical_executor_sha256': 'deb2d96c1590c176ae93f75cbf66161fe5a26f00401d9179f1082e3a1399f07d', 'historical_source_manifest_sha256': '8a19d7f1c8b5b6f57ce92d9bd0b3c84523878b48bd2a82a4231c8cecd66aed8b', 'historical_source_root': '/var/tmp/slack-update-acceptance/kernel-package-edge/local-source-v3', 'historical_v2_evidence_root_preserved': True, 'immediate_preflight_before_first_mutation_required': True, 'literal_root_substitution_alone_is_insufficient': True, 'new_absent_transaction_evidence_workdir_and_temp_required': True, 'new_exact_source_identity_and_synthetic_implementation_freeze_required': True, 'new_reviewed_reference_payload_and_config_identities_required': True, 'new_single_attempt_authorization_required': True, 'no_current_operational_writes_authorized': True, 'no_external_network_during_refresh_and_apply': True, 'no_manual_cleanup_of_preserved_sources_or_evidence': True, 'no_reference_apply_in_current_step': True, 'partial_failure_never_success_publication': True, 'predecessor_artifact': 'kernel-headers-6.18.44-x86-1.txz', 'predecessor_availability_independently_observed_now': False, 'predecessor_sha256': '3e7ab26d4a5ae1bd4e13f568dc7b8d6705eb670b94fed231ca01fefae2466a9d', 'predecessor_staging_is_future_bounded_mutation_not_authorized_now': True, 'publication_paths_and_package_or_boot_effects_require_later_design_review': True, 'reference_apply_reachable_only_after_candidate_binding': True, 'restore_header_package_names_slackpkg_conf_mirrors_state_geninitrd_and_boot_required': True, 'same_uninterrupted_boot_from_future_authorized_observation_to_transaction_required': True, 'state': 'future-design-implementation-and-authorization-required-not-implemented', 'step294_observed_boot_is_not_future_authorization_boot': True, 'success_publication_only_after_restoration_invariants': True, 'temporary_slackpkg_configuration_restored_exactly': True, 'v3_tagged_checksum_validator_must_not_be_reused_for_v4': True}, 'historical_failure': {'exact_target_candidates': 0, 'fresh_pkglist_sha256': 'e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855', 'fresh_pkglist_size_bytes': 0, 'reference_apply_reached': False, 'review_path': 'docs/reference/phase-1-kernel-package-edge-runtime-transaction-remediation-runtime-executor-v2-failed-result-review-and-strong-safe-pause.md', 'root_cause_path': 'docs/reference/phase-1-kernel-package-edge-runtime-transaction-remediation-empty-pkglist-root-cause-review.md', 'source_v3_checksum_record_format': 'GNU-tagged-MD5-path-not-last-field', 'source_v4_remediation': 'untagged-checksum-records-package-path-last-field', 'v4_runtime_refresh_observed': False}, 'machine_action_required': False, 'next_stage': 'phase-1-kernel-package-edge-runtime-transaction-remediation-post-local-source-v4-build-boundary-closure-and-strong-safe-pause', 'no_runtime_attempt_planned_in_289_298_route': True, 'order_is_future_requirements_not_current_execution_plan': True, 'pause_safe': False, 'repository_fixture_oracle_scope': 'text-and-contract-state-synthetic-review-only-not-production-selector-or-live-Slackpkg-proof', 'required_future_stage_order': ['fresh-target-source-revalidation', 'new-exact-executor-design-implementation-review-and-freeze', 'new-single-attempt-authorization', 'immediate-preflight-and-backup-traps', 'bounded-predecessor-staging-isolated-configuration', 'local-only-fresh-refresh', 'exact-same-transaction-target-only-candidate-binding', 'reference-apply', 'restore-and-verify-baseline', 'complete-evidence-and-conditional-success-publication', 'result-effect-review-and-authority-closure'], 'schema': 1, 'scope': 'repository-only-source-candidate-executor-boundary-review', 'source': {'accepted_builder_sha256': '38e83b300807fd23748bd2aa9e0ce86230da7a7270b6f01e9f54671331db80b7', 'builder_sha_scope': 'immutable-repository-context-no-current-build-authority', 'checksum_expected_row_count': 9, 'checksum_package_line_ends_in_txz': True, 'checksum_representation': 'untagged-gnu-md5sum-32-lowercase-hex-two-spaces-relative-path-last-field', 'compatibility_asc_non_authenticating': True, 'directories': ['extra', 'pasture', 'patches', 'slackware64', 'slackware64/d', 'testing'], 'directory_mode': '555', 'external_sha256_manifest_and_target_sha_are_identity_anchors': True, 'manifest': '/var/tmp/slack-update-acceptance/kernel-package-edge/local-source-v4.tree.sha256', 'manifest_sha256': 'a4b0fc122c6274c7fdf70907661511bcf6ba475a2aa3bc46b96e5bcbf6ed3db8', 'non_root_entry_count': 17, 'observation_is_point_in_time_not_current_or_continuous': True, 'observation_path': 'tests/fixtures/reference/acceptance/phase-1/phase-1-kernel-package-edge-runtime-transaction-remediation-post-local-source-v4-build-revalidation-freeze-observation.tsv', 'observation_provenance': 'semantic-transcription-of-user-returned-terminal-display', 'observation_sha256': '68efaab51288791ddcd515e7438dab6db7cbbe25be750549ce0b0cacf55db832', 'observed_boot_id': 'a5430a61-c988-4d52-9d5c-f20bb0a04016', 'one_exact_binding_per_eligible_generated_file': True, 'openpgp_signature_marker_forbidden': True, 'owner_uid_gid': '0:0', 'priority_trees': ['patches', 'slackware64', 'extra', 'pasture', 'testing'], 'regular_file_mode': '444', 'regular_files': ['./CHECKSUMS.md5', './CHECKSUMS.md5.asc', './ChangeLog.txt', './FILELIST.TXT', './PACKAGES.TXT', './extra/PACKAGES.TXT', './pasture/PACKAGES.TXT', './patches/PACKAGES.TXT', './slackware64/PACKAGES.TXT', './slackware64/d/kernel-headers-6.18.45-x86-1.txz', './testing/PACKAGES.TXT'], 'root': '/var/tmp/slack-update-acceptance/kernel-package-edge/local-source-v4', 'sidecar': '/var/tmp/slack-update-acceptance/kernel-package-edge/local-source-v4.tree.sha256.sha256', 'sidecar_sha256': '7cd7b99c730f388ddc949d22ad5ed98da703ea8050dfa31dc11456683f2176fc', 'source_edit_chmod_rebuild_or_overwrite_authorized': False, 'source_is_preserved_read_only_input': True, 'tagged_md5_records_forbidden': True, 'target_artifact': 'kernel-headers-6.18.45-x86-1.txz', 'target_relative_path': './slackware64/d/kernel-headers-6.18.45-x86-1.txz', 'target_sha256': 'c7b56b50f0abdec8f35628d526bb05488c257f667ab9c2be1a7a3e07d97da63c', 'uri': 'file:///var/tmp/slack-update-acceptance/kernel-package-edge/local-source-v4/'}, 'state': 'runtime-boundary-frozen-not-implemented-not-authorized', 'step': 297, 'strong_safe_pause': False}, 'phases': [{'index': 0, 'stage': 'immediate-preflight', 'effect': 'read-only', 'required_guard': 'new grant, fresh target/source/artifact/predecessor binding and same grant boot; safe absent owned paths'}, {'index': 1, 'stage': 'arm-idempotent-traps', 'effect': 'process-only', 'required_guard': 'EXIT/HUP/INT/TERM cleanup registered before first filesystem mutation'}, {'index': 2, 'stage': 'initialize-owned-workspace', 'effect': 'owned-files', 'required_guard': 'create exclusive owned evidence/temp roots; record partial construction on failure'}, {'index': 3, 'stage': 'capture-verify-backups', 'effect': 'owned-files', 'required_guard': 'capture exact production baseline bytes, modes and owner before package/config writes'}, {'index': 4, 'stage': 'stage-exact-predecessor', 'effect': 'package-state', 'required_guard': 'use separately validated exact predecessor artifact; no unrelated package action'}, {'index': 5, 'stage': 'isolate-local-configuration', 'effect': 'configuration-state', 'required_guard': 'use reviewed local v4 URI and isolated state; forbid external network during refresh/apply'}, {'index': 6, 'stage': 'refresh-new-pkglist', 'effect': 'owned-state', 'required_guard': 'absent-before/fresh-regular-nonempty-after; exit0 plus both-stream download-error guard'}, {'index': 7, 'stage': 'bind-exact-candidate', 'effect': 'read-only', 'required_guard': 'one exact eight-field target row; same-transaction source/pkglist/archive hashes before apply'}, {'index': 8, 'stage': 'reference-apply', 'effect': 'package-state', 'required_guard': 'only reviewed exact payload, after target-only binding; no boot or unrelated candidates'}, {'index': 9, 'stage': 'restore-production-baseline', 'effect': 'restoration', 'required_guard': 'restore target baseline header, config/mirrors/state and owned temporary changes'}, {'index': 10, 'stage': 'verify-restoration-invariants', 'effect': 'read-only', 'required_guard': 'verify header names/content, unrelated package records, config/state/GenInitrd/boot and preserved inputs'}, {'index': 11, 'stage': 'capture-complete-evidence', 'effect': 'owned-files', 'required_guard': 'per-stage stdout/stderr/exit, original failure/signal and cleanup outcomes; preserve failure evidence'}, {'index': 12, 'stage': 'publish-reviewed-result', 'effect': 'owned-files', 'required_guard': 'success only after all guards/restoration/evidence; failure/none never success'}], 'first_filesystem_mutation_index': 2, 'first_package_mutation_index': 4, 'candidate_binding_index': 7, 'apply_index': 8, 'future_authorization_requirements': {'new_detailed_executor_design_and_implementation_freeze': True, 'fresh_target_source_artifact_and_predecessor_validation': True, 'separately_reviewed_predecessor_staging_mutation': True, 'new_single_attempt_grant_consumed_on_invocation': True, 'no_retry_on_failure_signal_or_interruption': True, 'same_uninterrupted_boot_of_that_new_grant': True, 'immediate_preflight_before_first_mutation': True, 'reviewed_exact_reference_payload_and_configuration_identities': True, 'exclusive_absent_transaction_owned_work_and_temp_paths': True, 'v4_source_and_historical_evidence_preserved_no_manual_repair_or_cleanup': True}, 'restoration_contract': {'header_baseline': 'kernel-headers-6.18.45-x86-1', 'baseline_archive_sha256': 'c7b56b50f0abdec8f35628d526bb05488c257f667ab9c2be1a7a3e07d97da63c', 'predecessor_artifact': 'kernel-headers-6.18.44-x86-1.txz', 'predecessor_sha256': '3e7ab26d4a5ae1bd4e13f568dc7b8d6705eb670b94fed231ca01fefae2466a9d', 'required_verified_baseline_categories': ['header-package-names-and-content', 'unrelated-package-record-bytes', 'slackpkg-configuration-bytes-owner-and-mode', 'mirror-bytes-owner-and-mode', 'slackpkg-state-fingerprints', 'GenInitrd-fingerprint', 'boot-fingerprints', 'source-v4-v3-target-and-failed-v2-evidence', 'owned-temporary-state'], 'backup_verified_before_package_or_configuration_mutation': True, 'cleanup_idempotent_and_owned_only': True, 'original_failure_or_signal_status_preserved': True, 'cleanup_failure_separately_recorded_never_masks_original_failure': True, 'restoration_failure_keeps_pending_machine_obligation': True, 'evidence_capture_failure_keeps_pending_controller_obligation': True, 'success_publication_after_restoration_and_complete_evidence_only': True, 'accepted_source_and_prior_evidence_never_cleanup_targets': True, 'catchable_traps': ['EXIT', 'HUP', 'INT', 'TERM'], 'SIGKILL_crash_power_loss_atomic_restoration_guaranteed': False, 'uncatchable_exit_and_cleanup_status_remain_unknown': True, 'uncatchable_loss_requires_separate_result_effect_review_and_recovery_plan': True, 'no_atime_audit_or_continuous_host_immutability_claim': True}, 'publication_contract': {'success_requires_all_stages_exit0': True, 'success_requires_restoration_invariants': True, 'success_requires_complete_evidence': True, 'failure_evidence_is_not_success': True, 'partial_failed_or_interrupted_transaction_never_success': True, 'incomplete_evidence_is_not_closed_workstream': True, 'publication_failure_requires_review': True}, 'unresolved_execution_bindings': {'executor_sha256': None, 'reference_payload_sha256': None, 'configuration_sha256': None, 'transaction_work_root': None, 'new_grant_id': None, 'current_boot_id': None, 'current_predecessor_availability': None, 'resolution_required_in_later_design_revalidation_and_authorization': True}, 'fixture_oracle_scope': 'synthetic-stage-state-and-exact-accepted-candidate-oracle-not-production-executor-or-live-restoration-proof', 'repository_only': True, 'runtime_attempt_planned': False, 'machine_action_required': False, 'controller_action_required': False, 'pause_safe': False, 'strong_safe_pause': False, 'next_stage': 'phase-1-kernel-package-edge-runtime-transaction-remediation-local-source-v4-runtime-transaction-contract-freeze'}
    if json.dumps(contract,sort_keys=True,separators=(',',':')) != json.dumps(expected,sort_keys=True,separators=(',',':')):
        raise ValueError('reviewed transaction contract drift')
    return True

def validate_transaction_trace(trace, contract, candidate_gate):
    # This is a pure synthetic contract oracle, never an executor implementation.
    validate_transaction_contract(contract)
    def exact(actual, expected, label):
        if json.dumps(actual,sort_keys=True,separators=(',',':')) != json.dumps(expected,sort_keys=True,separators=(',',':')):
            raise ValueError(label)
    exact(sorted(trace),sorted(['context','events','verified_backups','candidate_fixture','cleanup','evidence',
        'publication','final_exit','grant_consumed','pending_machine_obligations','pending_controller_obligations']), 'trace schema')
    source=contract['frozen_source_candidate_executor']['source']
    expected_context=dict(new_grant=True,fresh_target_source_artifact_and_predecessor_validation=True,
        same_boot_of_new_grant=True,reviewed_executor_payload_and_configuration=True,exclusive_work_temp_absent=True,
        source_manifest_sha256=source['manifest_sha256'],source_target_sha256=source['target_sha256'],
        predecessor_sha256=contract['restoration_contract']['predecessor_sha256'])
    exact(trace['context'],expected_context,'stale or missing future gates')
    events=trace['events'];phases=contract['phases']
    if not isinstance(events,list) or not 1<=len(events)<=len(phases):raise ValueError('invalid stage prefix')
    signals={'HUP':129,'INT':130,'TERM':143}
    failed=False;lost=False;original_exit=0
    for index,event in enumerate(events):
        exact(sorted(event),['exit','outcome','signal','stage'],'event schema')
        exact(event['stage'],phases[index]['stage'],'out-of-order stage')
        status=event['outcome'];code=event['exit'];signal=event['signal']
        if status!='LOST' and (type(code) is not int or not 0<=code<=255):raise ValueError('invalid exit code')
        if status=='PASS':
            exact(code,0,'nonzero PASS');exact(signal,None,'signal on PASS')
        elif status=='FAIL':
            if code==0 or signal is not None:raise ValueError('invalid failure result')
            failed=True
        elif status=='INTERRUPTED':
            if signal not in ['HUP','INT','TERM'] or code!=signals[signal]:raise ValueError('invalid catchable signal status')
            failed=True
        elif status=='LOST':
            if signal not in ['KILL','CRASH','POWERLOSS'] or code is not None:raise ValueError('uncatchable stage status must remain unknown')
            failed=True;lost=True
        else:raise ValueError('unknown outcome')
        if failed:
            if index!=len(events)-1:raise ValueError('execution continued after failed stage')
            original_exit=code
    if not failed and len(events)!=len(phases):raise ValueError('incomplete successful prefix')
    mutation_attempted=len(events)>contract['first_filesystem_mutation_index']
    traps_armed=len(events)>2 or (len(events)==2 and events[-1]['outcome']=='PASS')
    backups_verified=len(events)>contract['first_package_mutation_index']
    exact(trace['verified_backups'],backups_verified,'backups must precede package/config mutation')
    if len(events)>contract['candidate_binding_index'] and events[contract['candidate_binding_index']]['outcome']=='PASS':
        if not isinstance(trace['candidate_fixture'],dict):raise ValueError('missing same-transaction candidate binding')
        candidate_gate(trace['candidate_fixture'],contract['frozen_source_candidate_executor'])
    elif trace['candidate_fixture'] is not None:
        raise ValueError('candidate binding claimed before accepted gate')
    cleanup=trace['cleanup']
    exact(sorted(cleanup),sorted(['armed','required','invoked','restoration_verified','exit']),'cleanup schema')
    exact(cleanup['armed'],traps_armed,'traps did not precede mutation')
    exact(cleanup['required'],mutation_attempted,'mutation cleanup requirement')
    exact(cleanup['invoked'],mutation_attempted and traps_armed and not lost,'cleanup invocation boundary')
    if type(cleanup['restoration_verified']) is not bool:raise ValueError('invalid restoration result type')
    restored=cleanup['restoration_verified']
    if (not mutation_attempted and not restored) or (mutation_attempted and lost and restored):
        raise ValueError('invented or missing restoration state')
    if cleanup['invoked']:
        if type(cleanup['exit']) is not int or not 0<=cleanup['exit']<=255:raise ValueError('invalid cleanup exit type')
        if restored!=(cleanup['exit']==0):raise ValueError('cleanup exit disagrees with verified restoration')
    elif cleanup['exit'] is not None:raise ValueError('uninvoked cleanup status must remain unknown')
    if not failed and not restored:raise ValueError('all-pass execution claims failed cleanup')
    evidence=trace['evidence']
    exact(sorted(evidence),sorted(['complete','streams_and_exits_captured','original_status_recorded','cleanup_recorded','owned_only','preserved_inputs']),'evidence schema')
    for key in evidence:
        if type(evidence[key]) is not bool:raise ValueError('invalid evidence boolean')
    exact(evidence['owned_only'],True,'evidence escapes owned paths')
    exact(evidence['preserved_inputs'],True,'source or prior evidence was modified')
    complete=evidence['complete']
    if complete != all(evidence[k] for k in ['streams_and_exits_captured','original_status_recorded','cleanup_recorded']):
        raise ValueError('incomplete evidence presented as complete')
    if lost and complete:raise ValueError('complete catchable evidence invented after uncatchable loss')
    publication_failed=failed and events[-1]['stage']=='publish-reviewed-result'
    if not failed:
        if not restored or not complete:raise ValueError('success before invariants and evidence')
        exact(trace['publication'],'success','missing complete success publication')
    else:
        exact(trace['publication'],'none' if not complete or publication_failed else 'failure','failed attempt cannot publish success')
    exact(trace['final_exit'],original_exit,'cleanup masked original failure or signal')
    exact(trace['grant_consumed'],True,'single-attempt grant reopened')
    machine_pending=mutation_attempted and not restored
    controller_pending=not complete or publication_failed
    exact(trace['pending_machine_obligations'],machine_pending,'unreviewed restoration obligations')
    exact(trace['pending_controller_obligations'],controller_pending,'unreviewed evidence/publication obligations')
    return 'success-eligible-fixture' if not failed else 'failed-incomplete-fixture' if machine_pending or controller_pending else 'failed-restored-fixture'

root=Path(sys.argv[1]);out=Path(sys.argv[2]).absolute();base='phase-1-kernel-package-edge-runtime-transaction-remediation-local-source-v4-runtime-transaction-contract-review';prior='phase-1-kernel-package-edge-runtime-transaction-remediation-post-local-source-v4-build-runtime-boundary-closure-resume-planning-boundary-review'
own_hashes={'docs/reference/phase-1-kernel-package-edge-runtime-transaction-remediation-local-source-v4-runtime-transaction-contract-review.md': '927a846704d3cb45e562ad0eba58987aca0189bc14107f669c14153c71175cd4', 'tests/fixtures/reference/acceptance/phase-1/phase-1-kernel-package-edge-runtime-transaction-remediation-local-source-v4-runtime-transaction-contract-review-contract.json': 'f341e76a83148ec8ee3a438cf8a82f469490bd8b9aed82afda97c9cddc12f291', 'tests/fixtures/reference/acceptance/phase-1/phase-1-kernel-package-edge-runtime-transaction-remediation-local-source-v4-runtime-transaction-contract-review-policy.json': 'c234a649f26f2ef83e18ca92d74b6f7b0c66e095d2f21c4ed8eda8a7a545c6da', 'tests/fixtures/reference/acceptance/phase-1/phase-1-kernel-package-edge-runtime-transaction-remediation-local-source-v4-runtime-transaction-contract-review-step299-user-acceptance.json': '0f89aac6e6d2a511f444410c08d8c5446a3e646caf3d95353869524c03a5eb53', 'tests/fixtures/reference/acceptance/phase-1/phase-1-kernel-package-edge-runtime-transaction-remediation-local-source-v4-runtime-transaction-contract-review.tsv': 'db5fa42e32ba08264edfaf1099262e0e01b3491dadbc77c1125e386108a32186'}
fixture=root/'tests/fixtures/reference/acceptance/phase-1'
def fail(message):raise SystemExit('ERROR: '+message)
if not out.is_dir() or out.resolve()!=out:fail('output directory must exist without symlink ancestors')
for rel,digest in own_hashes.items():
    p=root/rel
    if not p.is_file() or p.is_symlink() or p.resolve()!=p.absolute() or hashlib.sha256(p.read_bytes()).hexdigest()!=digest:
        fail('changed or unsafe review input: '+rel)
policy=json.loads((fixture/(base+'-policy.json')).read_text());accepted=policy['accepted_checkpoint']
historical={}
for rel,digest in accepted['sha256_bindings'].items():
    p=root/rel
    if Path(rel).is_absolute() or '..' in Path(rel).parts or not p.is_file() or p.is_symlink() or p.resolve()!=p.absolute() or not p.resolve().is_relative_to(root):
        fail('unsafe accepted path: '+rel)
    data=p.read_bytes()
    if rel=='CHANGELOG.md':data=data[-accepted['changelog_size_bytes']:]
    if hashlib.sha256(data).hexdigest()!=digest:fail('accepted299 byte drift: '+rel)
    historical[rel]=data
receipt=json.loads((root/accepted['evidence_path']).read_text());data=receipt['text'].encode('utf-8')
if hashlib.sha256(data).hexdigest()!=accepted['evidence_sha256'] or receipt['original_display_sha256']!=accepted['evidence_sha256'] or receipt['original_display_size_bytes']!=len(data):fail('user checkpoint evidence changed')
if len([x for x in data.decode().splitlines() if x.startswith('PASS: ')])!=119 or 'Result: PASS (119 passes, 0 failures)' not in data.decode().splitlines() or b'[main 435df6b]' not in data or b'acc26e3..435df6b  main -> main' not in data:fail('full user119 acceptance/commit/push missing')
contract=json.loads((root/policy['contract_path']).read_text());validate_transaction_contract(contract)
previous=json.loads(historical['tests/fixtures/reference/acceptance/phase-1/'+prior+'-policy.json'])
if previous['next_stage']!=base or contract['frozen_source_candidate_executor']!=previous['accepted_runtime_boundary']:fail('predecessor gate or frozen contract changed')
authorized=dict.fromkeys(previous['authorization'],False);authorized['repository_only_transaction_contract_freeze_authorized']=True
if policy['authorization']!=authorized or any(policy[k] is not False for k in ['machine_action_required','controller_action_required','pause_safe','strong_safe_pause','user_step300_checkpoint_confirmed']):fail('premature authority or checkpoint claim')
publish=[base+suffix for suffix in ['-policy.json','-contract.json','-step299-user-acceptance.json','.tsv']]
for name in publish:
    if (out/name).exists() or (out/name).is_symlink():fail('review output already exists')
with tempfile.TemporaryDirectory(prefix='step300-exact299-') as directory:
    snapshot=Path(directory)/'slack-update'
    for rel,data in historical.items():
        p=snapshot/rel;p.parent.mkdir(parents=True,exist_ok=True);p.write_bytes(data)
    result=subprocess.run(['bash',str(snapshot/'tests/reference'/('test-'+prior+'-harness.sh'))],capture_output=True,text=True)
    if result.returncode or 'Result: PASS (119 passes, 0 failures)' not in result.stdout.splitlines():
        fail('full119 accepted predecessor failed\n'+result.stdout+result.stderr)
created=[]
try:
    for name in publish:
        with (out/name).open('xb') as handle:
            created.append(out/name);handle.write((fixture/name).read_bytes())
except BaseException:
    for p in reversed(created):p.unlink()
    raise
for key,value in dict(step300_transaction_contract_review_status='PASS',accepted_step299_revalidated='PASS (119 passes, 0 failures)',
    production_executor_entered='no',live_target_observation_performed='no',runtime_attempt_authorized='no',
    machine_action_required='no',controller_action_required='no',pause_safe='no',strong_safe_pause='no',next_stage=policy['next_stage']).items():
    print(key+'\t'+value)
PYREVIEW
