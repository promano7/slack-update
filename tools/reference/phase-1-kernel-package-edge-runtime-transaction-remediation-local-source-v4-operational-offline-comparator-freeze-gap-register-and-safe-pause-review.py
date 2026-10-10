#!/usr/bin/env python3
"""Validate a repository artifact freeze without granting native authority."""
from pathlib import Path
import hashlib
import json
import re

SCOPE = 'repository-offline-evidence-comparator-workstream349-358-only'
PRIOR = 'phase-1-kernel-package-edge-runtime-transaction-remediation-local-source-v4-operational-offline-comparator-full-contract-gap-reconciliation-review'
FIXTURE = 'tests/fixtures/reference/acceptance/phase-1/'


def exact(value, expected, label):
    if type(value) is not type(expected) or json.dumps(value, sort_keys=True) != json.dumps(expected, sort_keys=True):
        raise ValueError(label)


def sha(raw):
    return hashlib.sha256(raw).hexdigest()


def display_comparison(text):
    """Decode only Markdown escapes and whitespace for explicit display comparison."""
    return re.sub(r'\s+', ' ', re.sub(r'\\([\\`*_{}\[\]()#+\-.!>@~])', r'\1', text)).strip()


def validate_return(confirmation, receipt, policy):
    raw = receipt['text'].encode('utf-8')
    exact(sha(raw), policy['accepted_receipt_sha256'], 'original357 receipt hash')
    exact(len(raw), policy['accepted_receipt_size_bytes'], 'original357 receipt size')
    exact(receipt['original_display_sha256'], sha(raw), 'receipt hash retained')
    exact(receipt['original_display_size_bytes'], len(raw), 'receipt size retained')
    exact(receipt['ordered_output_normalization'], 'raw-preserved;explicit-markdown-display-comparison-only', 'raw display must be retained')
    display = display_comparison(receipt['text'])
    summary = 'Result: PASS (931 passes, 0 failures)'
    exact(display.count(summary), 1, 'single931 summary')
    before, after = display.split(summary)
    start = before.index('PASS: ')
    labels = ['PASS: ' + item.strip() for item in before[start:].removeprefix('PASS: ').split(' PASS: ')]
    exact(labels, policy['accepted_ordered357_labels'], 'all931 original labels in order')
    message = policy['accepted_commit_message']
    exact(after.count('[main e5328fb] ' + message), 1, 'exact reported357 commit')
    exact(after.count('10 files changed, 45402 insertions(+)'), 1, 'exact ten-file357 scope')
    paths = re.findall(r'create mode 100644 (\S+)', after)
    exact(paths, policy['accepted_step357_paths'], 'exact nine created357 paths')
    exact(after.count('48b0d13..e5328fb main -> main'), 1, 'successful reported357 push')
    head = 'e5328fb (HEAD -> main, origin/main, origin/HEAD) ' + message
    exact(after.count(head), 2, 'two matching reported357 heads')
    if 'step357_overlay_application_status PASS' not in before:
        raise ValueError('reported357 overlay missing')
    commands = 'git push origin main git status --short git log -1 --oneline git log -1 --oneline origin/main'
    if commands not in before or not after.endswith(head + ' ' + head + ' promano@pc-arch ~/Descargas $ &#x20;'):
        raise ValueError('complete ordered status and final prompt required')
    for key, expected in {'step': 357, 'commit_prefix': 'e5328fb', 'commit_full': None,
                          'acceptance_result': 'PASS (931 passes, 0 failures)',
                          'evidence_sha256': sha(raw), 'evidence_size_bytes': len(raw),
                          'strong_safe_pause': False, 'runtime_authority': False}.items():
        exact(confirmation[key], expected, 'confirmation ' + key)
    for key in ('user_application_completed', 'user_harness_completed', 'user_commit_and_push_completed',
                'user_head_matches_origin', 'user_worktree_clean', 'complete_ordered_return_matches_prepared_and_installed'):
        exact(confirmation[key], True, 'reported357 ' + key)
    return True


def validate_freeze(value, ledger, source_map, policy):
    expected = ledger['accepted_artifact_registry349_356'] + [
        {'step': 357, 'path': path, 'sha256': policy['baseline_sha256_bindings'][path],
         'scope': 'accepted-repository-artifact-not-native-implementation'}
        for path in policy['accepted_step357_paths']]
    exact(value['frozen_artifact_registry349_357'], expected, '81 full accepted artifact bindings')
    exact(len(expected), 81, '81 frozen artifacts')
    exact(value['accepted_checkpoint_chain348_357'][:-1], ledger['accepted_checkpoint_chain348_356'], 'complete prior receipt chain')
    exact(value['accepted_checkpoint_chain348_357'][-1], policy['accepted357_chain_row'], 'complete357 chain row')
    exact(value['original_pause_conditions'], ledger['original_pause_conditions'], 'nine original pause conditions')
    exact(value['counts'], ledger['counts'], 'all original obligations indexed')
    for suffix in ('reconciliation-ledger', 'full-contract-source-map', 'retained-obligations', 'reconciliation-contract'):
        path = FIXTURE + PRIOR + '-' + suffix + '.json'
        exact(value['exact357_sources'][suffix], {'path': path, 'sha256': policy['baseline_sha256_bindings'][path]}, 'whole357 source ' + suffix)
    exact(value['frozen_artifact_registry339_347'], source_map['frozen_artifact_registry339_347'], 'prior core freeze intact')
    for key in ('offline_repository_artifacts_frozen', 'scoped_pause_candidate', 'current358_user_acceptance_pending',
                'stop_after_complete358_acceptance', 'future_work_requires_new_user_request', 'production_entry_closed'):
        exact(value[key], True, 'repository boundary ' + key)
    for key in ('strong_safe_pause', 'user_step358_checkpoint_confirmed', 'actual_operational_implementation_frozen',
                'actual_native_refinement_complete', 'actual_dynamic_graph_complete', 'actual_independent_oracle_selected',
                'operational_conformance', 'operational_readiness', 'runtime_authority', 'new_runtime_work_authorized',
                'historical_binding_or_authority_reuse_allowed', 'machine_action_required', 'controller_action_required',
                'new_batch_machine_cleanup_required', 'new_batch_controller_cleanup_required',
                'later_current_refresh_invalidates_repository_only_pause', 'phase1_matrix_complete',
                'kernel_package_edge_complete', 'phase2_open'):
        exact(value[key], False, 'native or future scope closed ' + key)
    for key, expected in {'step': 358, 'scope': SCOPE, 'schema': 1, 'native_cases_run': 0, 'native_proofs_added': 0,
                          'actual_host_state': 'unobserved-not-claimed-absent', 'actual_live_bindings': None,
                          'next_authorized_stage': None, 'last_confirmed_strong_safe_pause_step': 348}.items():
        exact(value[key], expected, 'scoped freeze ' + key)
    return True


def validate_gaps(value, ledger, source_map):
    for key in ('full_normative_rows', 'full_original_native_gap_rows348', 'full_original_evidence_group_rows335',
                'full_original_independence_contract335'):
        exact(value[key], ledger[key], 'whole normative native obligation ' + key)
    exact(value['full_original_contracts320_327'], source_map['full_original_contracts320_327'], 'eight whole original contracts')
    for key, expected in {'scope': SCOPE, 'step': 358, 'runtime_authority': False, 'native_cases_run': 0,
                          'native_proofs_added': 0, 'actual_native_refinement_complete': False,
                          'operational_conformance': False, 'actual_live_bindings': None,
                          'actual_host_state': 'unobserved-not-claimed-absent'}.items():
        exact(value[key], expected, 'retained gaps ' + key)
    return True


def validate_conditions(value, freeze):
    exact(value['scope'], SCOPE, 'conditions scope')
    exact(value['step'], 358, 'conditions358')
    exact([row['id'] for row in value['conditions']], freeze['original_pause_conditions'], 'nine exact ordered conditions')
    for i, row in enumerate(value['conditions']):
        exact(row['position'], i, 'condition position')
        exact(row['requirement'], row['id'], 'full original condition preserved')
        exact(row['status'], 'pending-current358-complete-user-return' if i == 0 else 'repository-scope-checked-with-native-blockers-retained', 'conditional current358 receipt')
        exact(row['actual_native_evidence'], None, 'no native evidence')
        exact(row['current358_actual_user_confirmation'], None, 'no actual358 confirmation')
    for key in ('actual_strong_safe_pause_confirmed', 'actual_global_host_closure', 'runtime_authority', 'private_eligibility_is_actual_confirmation'):
        exact(value[key], False, 'no actual closure from private eligibility')
    exact(value['external_confirmation_rule'], freeze['pause_confirmation_rule'], 'complete final receipt required')
    return True


def private_pause_eligibility(value, conditions):
    """Pure private fixture eligibility. Does not accept a user return or grant rights."""
    fields = {'schema', 'step', 'scope', 'origin', 'checks', 'actual_host_state', 'actual_live_bindings', 'runtime_authority'}
    if type(value) is not dict or set(value) != fields:
        raise ValueError('closed private eligibility fields required')
    for key, expected in {'schema': 1, 'step': 358, 'scope': SCOPE, 'origin': 'synthetic-private-fixture',
                          'actual_host_state': 'unobserved-not-claimed-absent', 'actual_live_bindings': None,
                          'runtime_authority': False}.items():
        exact(value[key], expected, 'private fixture ' + key)
    checks = value['checks']
    names = [row['id'] for row in conditions['conditions']]
    if type(checks) is not dict or set(checks) != set(names) or any(type(v) is not bool for v in checks.values()):
        raise ValueError('all nine exact boolean reports required')
    pending = [name for name in names if not checks[name]]
    return {'model_scoped_pause_confirmation_eligible': not pending, 'model_pending_conditions': pending,
            'actual_strong_safe_pause_confirmed': False, 'actual_global_host_closure': False,
            'actual_operational_conformance': False, 'actual_runtime_authority': False,
            'actual_native_cases_run': 0, 'actual_native_proofs_added': 0}
