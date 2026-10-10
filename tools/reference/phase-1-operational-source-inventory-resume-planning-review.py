#!/usr/bin/env python3
"""Validate source-review planning data; no native action or source execution."""
import hashlib
import json
import re

SCOPE = 'repository-source-inventory-and-roadmap-workstream359-368-only'
STAGES = (
    'resume-plan', 'bounded-source-inventory-contract', 'read-only-source-inventory',
    'entrypoint-and-callsite-review', 'external-dependency-register',
    'effect-and-lifetime-review', 'native-implementation-prerequisites',
    'source-and-native-gap-reconciliation', 'readme-roadmap-reconciliation',
    'source-inventory-freeze-and-pause')
BOUNDARIES = {
    'scope': SCOPE, 'machine_action_required': False, 'controller_action_required': False,
    'runtime_authority': False, 'production_entry_closed': True, 'phase2_open': False,
    'phase1_matrix_complete': False, 'kernel_package_edge_complete': False,
    'native_cases_run': 0, 'native_proofs_added': 0, 'operational_conformance': False,
    'operational_readiness': False, 'actual_host_state': 'unobserved-not-claimed-absent',
    'actual_live_bindings': None, 'historical_authority_reuse_allowed': False,
    'native_successor_selected': False, 'native_collector_selected': False,
    'native_verifier_selected': False, 'current_step_strong_safe_pause': False,
    'last_confirmed_strong_safe_pause_step': 358,
    'final_pause_requires_complete_user_receipt': True,
    'later_current_refresh_invalidates_repository_pause': False
}
SOURCE_ROLES = (
    ('tools/reference/slack-update-reference.sh', 'reference-specification-source-for-review-only'),
    ('tools/reference/phase-1-kernel-package-edge-runtime-transaction-remediation-v2-executor-body.sh',
     'historical-worker-body-not-a-selected-native-successor'),
    ('tools/reference/phase-1-kernel-package-edge-runtime-transaction-remediation-v2-executor-build.sh',
     'historical-generator-source-for-review-only'),
    ('tools/reference/phase-1-kernel-package-edge-runtime-transaction-remediation-v2-executor.sh',
     'historical-generated-artifact-not-a-second-independent-worker'))
OLD = 'tests/fixtures/reference/acceptance/phase-1/phase-1-kernel-package-edge-runtime-transaction-remediation-local-source-v4-operational-offline-comparator-freeze-gap-register-and-safe-pause-review-'


def exact(value, expected, label):
    same_type = type(value) is type(expected)
    if isinstance(value, (set, type, bytes)):
        equal = value == expected
    else:
        equal = json.dumps(value, sort_keys=True) == json.dumps(expected, sort_keys=True)
    if not same_type or not equal:
        raise ValueError(label)


def sha(raw):
    return hashlib.sha256(raw).hexdigest()


def validate_return(confirmation, receipt, policy):
    exact(receipt['schema'], 1, 'receipt schema')
    exact(receipt['step'], 358, 'receipt step')
    exact(receipt['normalization'], 'none', 'receipt normalization')
    exact(receipt['basis'], 'complete-original-user-return-not-independent-host-or-GitHub-inspection', 'receipt basis')
    raw = receipt['text'].encode('utf-8')
    exact(sha(raw), policy['accepted_receipt_sha256'], 'original receipt SHA')
    exact(len(raw), policy['accepted_receipt_size_bytes'], 'original receipt bytes')
    exact(receipt['sha256'], sha(raw), 'receipt digest declaration')
    exact(receipt['size_bytes'], len(raw), 'receipt size declaration')
    text = receipt['text']
    exact([line for line in text.splitlines() if line.startswith('PASS: ')],
          policy['expected_ordered358_labels'], 'all292 ordered original PASS labels')
    exact(text.count('Result: PASS (292 passes, 0 failures)'), 1, 'single original summary')
    message = 'Phase 1 step 358: freeze offline comparators and conditional safe pause'
    exact(text.count('[main 64b63ed] ' + message), 1, 'reported commit')
    exact(text.count('10 files changed, 44747 insertions(+)'), 1, 'reported scope')
    exact(re.findall(r'^ create mode 100644 (.+)$', text, flags=re.M),
          policy['accepted_step358_created_paths'], 'nine reported created paths')
    exact(text.count('e5328fb..64b63ed  main -> main'), 1, 'reported successful push')
    head = '64b63ed (HEAD -> main, origin/main, origin/HEAD) ' + message
    exact(text.count(head), 2, 'two matching reported heads')
    if 'step358_overlay_application_status\tPASS' not in text:
        raise ValueError('overlay receipt missing')
    if not text.endswith(head + '\n' + head + '\npromano@pc-arch ~/Descargas $ \n'):
        raise ValueError('complete ordered reported clean-status/head ending missing')
    for key, value in {
        'step': 358, 'commit_prefix': '64b63ed', 'commit_full': None,
        'evidence_sha256': sha(raw), 'evidence_size_bytes': len(raw),
        'acceptance_result': 'PASS (292 passes, 0 failures)',
        'scope': 'repository-offline-evidence-comparator-workstream349-358-only',
        'strong_safe_pause': True, 'scoped_strong_safe_pause': True,
        'actual_global_host_closure': False, 'actual_live_bindings': None,
        'actual_host_state': 'unobserved-not-claimed-absent',
        'runtime_authority': False, 'native_cases_run': 0, 'native_proofs_added': 0,
        'phase1_matrix_complete': False, 'kernel_package_edge_complete': False,
        'phase2_open': False, 'production_entry_closed': True,
        'next_authorized_stage': None, 'batch_stopped': True,
        'confirmation_external_to_immutable_repository': True
    }.items():
        exact(confirmation[key], value, 'confirmed358 ' + key)
    for key in ('user_application_completed', 'user_harness_completed',
                'user_commit_and_push_completed', 'user_head_matches_origin',
                'user_worktree_clean', 'complete_ordered_return_matches_prepared_and_installed'):
        exact(confirmation[key], True, 'confirmed receipt ' + key)
    return True


def validate_plan(plan):
    exact(plan['schema'], 1, 'plan schema')
    exact(plan['step'], 359, 'plan step')
    exact(plan['accepted_predecessor_step'], 358, 'plan predecessor')
    exact(plan['accepted_predecessor_commit_prefix'], '64b63ed', 'plan predecessor commit')
    exact(plan['authorization_basis'],
          'new-user-request-for-8-to-12-step-batch-with-final-README-reconciliation', 'new user scope')
    exact(plan['state'], 'prepared-user-overlay-test-commit-push-receipt-pending', 'prepared state')
    exact(plan['boundaries'], BOUNDARIES, 'repository-only boundaries')
    exact(plan['readme_reconciliation_step'], 367, 'README before final freeze')
    exact(plan['conditional_pause_step'], 368, 'final pause candidate')
    exact(plan['next_preparable_step_after_complete359_acceptance'], 360, 'next after receipt')
    rows = plan['roadmap']
    exact(len(rows), 10, 'ten-step batch')
    for step, stage, row in zip(range(359, 369), STAGES, rows):
        exact(set(row), {'step', 'stage', 'entry_requires_confirmed_step', 'runtime_authorized', 'deliverable'}, 'closed roadmap row')
        exact(row['step'], step, 'ordered step')
        exact(row['stage'], stage, 'ordered stage')
        exact(row['entry_requires_confirmed_step'], step-1, 'confirmed predecessor required')
        exact(row['runtime_authorized'], False, 'no runtime stage')
        if not isinstance(row['deliverable'], str) or not row['deliverable'].strip():
            raise ValueError('deliverable required')
    exact(plan['requirements_retained_by_exact_binding'],
          [OLD + tail + '.json' for tail in ('native-gap-register', 'freeze', 'pause-conditions')],
          'full retained requirements')
    return True


def validate_source_roots(rows, source_bytes):
    exact(len(rows), 4, 'four explicit review roots')
    exact(set(source_bytes), {p for p, _ in SOURCE_ROLES}, 'closed source input set')
    for row, (path, role) in zip(rows, SOURCE_ROLES):
        exact(set(row), {'path', 'sha256', 'size_bytes', 'role', 'review_selection_only',
                         'execution_authorized', 'actual_native_binding'}, 'closed source row')
        exact(row['path'], path, 'source path')
        exact(row['role'], role, 'source role')
        raw = source_bytes[path]
        exact(type(raw), bytes, 'source bytes only')
        exact(row['sha256'], sha(raw), 'exact review source')
        exact(row['size_bytes'], len(raw), 'source length')
        exact(row['review_selection_only'], True, 'review scope')
        exact(row['execution_authorized'], False, 'historical executable not authorized')
        exact(row['actual_native_binding'], None, 'no native successor selection')
    return True


def validate_retained_gaps(gaps, policy):
    exact([r['inherited_gap']['id'] for r in gaps['full_original_native_gap_rows348']],
          policy['inherited_gap_ids'], 'all16 exact inherited gap identities')
    exact(len(policy['inherited_gap_ids']), 16, 'sixteen gaps')
    for row in gaps['full_original_native_gap_rows348']:
        exact(row['status'], 'required-not-selected-refined-or-proven', 'gap unresolved')
        exact(row['native_status_promoted'], False, 'no promotion')
        for field in ('actual_independent_evidence', 'actual_model_or_component', 'actual_native_event_relation'):
            exact(row[field], None, 'no actual gap evidence')
    for field in ('native_cases_run', 'native_proofs_added'):
        exact(gaps[field], 0, 'no native progress')
    for field in ('runtime_authority', 'operational_conformance', 'actual_native_refinement_complete'):
        exact(gaps[field], False, 'no native claim')
    return True
