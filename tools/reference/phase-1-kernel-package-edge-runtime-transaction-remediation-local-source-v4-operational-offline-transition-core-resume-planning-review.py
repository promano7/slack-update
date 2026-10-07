#!/usr/bin/env python3
"""Repository-only planning verifier; no operational effects or authority."""
from pathlib import Path
import hashlib
import json
import sys

BASE = 'phase-1-kernel-package-edge-runtime-transaction-remediation-local-source-v4-operational-offline-transition-core-resume-planning-review'
FIXTURE = 'tests/fixtures/reference/acceptance/phase-1/'
OWN_HASHES = {'docs/reference/phase-1-kernel-package-edge-runtime-transaction-remediation-local-source-v4-operational-offline-transition-core-resume-planning-review.md': '8b51cca8dd6e3a2d84d454cccf13620d80924b8e7a02a02cd41cb83560c1548a', 'tests/fixtures/reference/acceptance/phase-1/phase-1-kernel-package-edge-runtime-transaction-remediation-local-source-v4-operational-offline-transition-core-resume-planning-review-roadmap.tsv': '7b8cb0a85aad121014a74d88cc6443750b3d1b9082f9bce597c5c3051e0ee58f', 'tests/fixtures/reference/acceptance/phase-1/phase-1-kernel-package-edge-runtime-transaction-remediation-local-source-v4-operational-offline-transition-core-resume-planning-review-retained-obligations.json': '8be3fb9a1b10103936194fb09d96c3d4987443421b95b22a0946df6e8572be09', 'tests/fixtures/reference/acceptance/phase-1/phase-1-kernel-package-edge-runtime-transaction-remediation-local-source-v4-operational-offline-transition-core-resume-planning-review-policy.json': 'd5609c69cc3c8a36cfc4fdf72dada844551ad8e9dcc06a2e4cbff5a2814d0c97', 'tests/fixtures/reference/acceptance/phase-1/phase-1-kernel-package-edge-runtime-transaction-remediation-local-source-v4-operational-offline-transition-core-resume-planning-review-plan.json': '30c422ae7a3adf21a4ebb9b8867b6d817120a60a70de6fc161ccf89e4887375b', 'tests/fixtures/reference/acceptance/phase-1/phase-1-kernel-package-edge-runtime-transaction-remediation-local-source-v4-operational-offline-transition-core-resume-planning-review-checkpoint-confirmation.json': '43dcdac83271b7bf6c59e3d631bc4b272a4932642b53d103515aed56aec6f92c', 'tests/fixtures/reference/acceptance/phase-1/phase-1-kernel-package-edge-runtime-transaction-remediation-local-source-v4-operational-offline-transition-core-resume-planning-review-step338-user-acceptance.json': '60229151a82c16173978135a81b3fb9fb09f3e33dda78ae725ad1a1cf4ca5a43'}
COUNTS = {'capabilities': 7, 'cross_obligations': 10, 'domains': 30, 'macro_cuts': 81, 'macro_relations': 95, 'native_cases': 52, 'native_gaps': 16, 'native_proofs': 46, 'nominal_interfaces': 26, 'nominal_types': 35, 'owned_microsteps': 9, 'phases': 27, 'rights_windows': 9}
STAGES = ['resume-plan', 'state-event-schema', 'admission-launch-reducer', 'bootstrap-guard-reducer', 'worker-owned-stage-reducer', 'failure-recovery-reducer', 'target-publication-reducer', 'adversarial-sequence-tests', 'contract-refinement-reconciliation', 'offline-core-freeze-and-pause']
PLAN_KEYS = ['actual_host_state', 'actual_live_bindings', 'compatibility_claim', 'compatibility_targets', 'conditional_pause_step', 'controller_action_required', 'core_execution_scope', 'core_implemented', 'counts', 'future_native_implementation_selected', 'historical_bindings_reusable', 'kernel_package_edge_complete', 'last_confirmed_strong_safe_pause_step', 'later_preparation_requires_complete_predecessor_return', 'machine_action_required', 'model_observations_are_native_evidence', 'native_cases_run', 'native_effect_requests_allowed', 'native_proofs_added', 'new_user_request', 'operational_conformance', 'operational_readiness', 'pause_conditions', 'phase1_matrix_complete', 'phase2_open', 'preferred_step_range', 'production_entry_closed', 'route', 'runtime_authority', 'schema', 'scope', 'step', 'stop_after_complete348_acceptance', 'strong_safe_pause', 'user_step339_checkpoint_confirmed']
FALSE_FIELDS = ['controller_action_required', 'core_implemented', 'future_native_implementation_selected', 'historical_bindings_reusable', 'kernel_package_edge_complete', 'machine_action_required', 'model_observations_are_native_evidence', 'native_effect_requests_allowed', 'operational_conformance', 'operational_readiness', 'phase1_matrix_complete', 'phase2_open', 'runtime_authority', 'strong_safe_pause', 'user_step339_checkpoint_confirmed']
TRUE_FIELDS = ['later_preparation_requires_complete_predecessor_return', 'new_user_request', 'production_entry_closed', 'stop_after_complete348_acceptance']

def sha(data):
    return hashlib.sha256(data).hexdigest()

def exact(value, expected, label):
    # bool is a subclass of int: JSON protocol comparisons must preserve types.
    if type(value) is not type(expected) or value != expected:
        raise ValueError(label)

def safe_path(root, relative):
    if not isinstance(relative, str) or not relative or '\\' in relative:
        raise ValueError('invalid repository path')
    parts = relative.split('/')
    if any(p in ('', '.', '..') for p in parts) or relative.startswith('/'):
        raise ValueError('unsafe repository path')
    p = root / relative
    if p.is_symlink() or p.resolve() != p.absolute() or not p.is_file():
        raise ValueError('missing or unsafe repository file: ' + relative)
    return p

def validate_plan(plan, conditions):
    exact(sorted(plan), PLAN_KEYS, 'closed planning schema')
    exact(plan['schema'], 1, 'schema')
    exact(plan['step'], 339, 'current step')
    exact(plan['scope'], 'repository-offline-transition-core-workstream339-348-only', 'repository scope')
    exact(plan['last_confirmed_strong_safe_pause_step'], 338, 'last confirmed pause')
    exact(plan['preferred_step_range'], [339, 348], 'ten-step batch')
    exact(plan['conditional_pause_step'], 348, 'conditional pause')
    exact(plan['counts'], COUNTS, 'all retained obligation counts')
    for k, v in plan['counts'].items():
        exact(v, COUNTS[k], 'typed count ' + k)
    for k in FALSE_FIELDS:
        exact(plan[k], False, 'no actual authority/completion: ' + k)
    for k in TRUE_FIELDS:
        exact(plan[k], True, 'required planning boundary: ' + k)
    for k in ('native_cases_run', 'native_proofs_added'):
        exact(plan[k], 0, 'no native cases or proofs')
    exact(plan['actual_live_bindings'], None, 'no live binding')
    exact(plan['actual_host_state'], 'unobserved-not-claimed-absent', 'unknown host')
    exact(plan['compatibility_targets'], ['Slackware-15.0', 'Slackware-current'], 'two native targets')
    exact(plan['compatibility_claim'], 'not-tested-natively', 'no platform compatibility claim')
    exact(plan['core_execution_scope'], 'pure-in-memory-data-transitions-only', 'no operational dispatcher')
    exact(plan['pause_conditions'], conditions, 'all original pause conditions')
    exact(len(plan['route']), 10, 'ten ordered stages')
    for offset, row in enumerate(plan['route']):
        exact(sorted(row), ['deliverable', 'entry_requires_confirmed_step', 'runtime_authorized', 'stage', 'status', 'step'], 'closed route')
        step = 339 + offset
        exact(row['step'], step, 'ordered route step')
        exact(row['entry_requires_confirmed_step'], step - 1, 'complete predecessor required')
        exact(row['stage'], STAGES[offset], 'selected repository deliverable')
        exact(row['runtime_authorized'], False, 'roadmap never authority')
        exact(row['status'], 'current-preparation' if offset == 0 else 'future-repository-work', 'future preparation pending')
        if type(row['deliverable']) is not str or not row['deliverable'].strip():
            raise ValueError('missing stage deliverable')
    return True

def validate_retained(retained, history):
    exact(sorted(retained), ['contract_bindings', 'normative_rule', 'pause_conditions', 'registers', 'schema', 'source_bindings', 'step'], 'closed retained index')
    exact(retained['schema'], 1, 'retained schema')
    exact(retained['step'], 339, 'retained step')
    exact(sorted(retained['source_bindings']), ['freeze', 'gaps'], 'full normative sources')
    sources = {}
    for role, binding in retained['source_bindings'].items():
        exact(sorted(binding), ['path', 'sha256'], 'closed source binding')
        if binding['path'] not in history or sha(history[binding['path']]) != binding['sha256']:
            raise ValueError('normative source content changed')
        sources[role] = json.loads(history[binding['path']])
    freeze = sources['freeze']; gaps = sources['gaps']
    exact(freeze['step'], 338, 'original freeze')
    exact(gaps['step'], 338, 'original gaps')
    exact(retained['contract_bindings'], freeze['exact_contract_bindings'], 'all frozen contract bindings')
    for binding in retained['contract_bindings'].values():
        if binding['path'] not in history or sha(history[binding['path']]) != binding['sha256']:
            raise ValueError('frozen contract changed')
    conditions = [x['id'] for x in freeze['conditional_pause_requirements']]
    exact(retained['pause_conditions'], conditions, 'nine original pause conditions')
    exact(len(conditions), 9, 'nine pause conditions')
    exact(sorted(retained['registers']), sorted(COUNTS), 'all inherited registers')
    expected_fields = {'native_proofs': ('gaps', 'qualified_proofs'), 'native_cases': ('gaps', 'native_case_templates'), 'native_gaps': ('gaps', 'native_gap_register'), 'macro_cuts': ('gaps', 'macro_cut_obligations'), 'owned_microsteps': ('gaps', 'owned_stage7_microsteps'), 'domains': ('freeze', 'effect_domain_reconciliation'), 'macro_relations': ('freeze', 'all95_macro_design_relations'), 'phases': ('freeze', 'all27_phase_boundaries'), 'nominal_interfaces': ('freeze', 'all26_nominal_interfaces'), 'nominal_types': ('freeze', 'all35_nominal_types'), 'rights_windows': ('freeze', 'authority_window_reconciliation'), 'capabilities': ('freeze', 'seven_capability_reconciliation'), 'cross_obligations': ('freeze', 'ten_cross_obligation_reconciliation')}
    idkeys = {'native_proofs': 'qualified_id', 'macro_cuts': 'id', 'owned_microsteps': 'source_step', 'domains': 'id', 'phases': 'id', 'nominal_interfaces': 'id', 'nominal_types': 'name', 'rights_windows': 'window', 'capabilities': 'id', 'cross_obligations': 'id'}
    for name, index in retained['registers'].items():
        exact(sorted(index), ['rows', 'source', 'source_field'], 'closed obligation register')
        role, field = expected_fields[name]
        exact(index['source'], role, 'original obligation source')
        exact(index['source_field'], field, 'original obligation field')
        rows = sources[role][field]
        exact(len(index['rows']), COUNTS[name], 'complete retained register ' + name)
        exact(len(rows), COUNTS[name], 'complete normative register ' + name)
        for position, (entry, original) in enumerate(zip(index['rows'], rows)):
            exact(sorted(entry), ['canonical_row_sha256', 'id', 'position'], 'closed indexed obligation')
            identifier = original[idkeys[name]] if name in idkeys else original['platform'] + '/' + original['case_id'] if name == 'native_cases' else original['inherited_gap']['id'] if name == 'native_gaps' else original['source'] + '->' + original['target']
            exact(entry['position'], position, 'ordered original obligation')
            exact(entry['id'], identifier, 'original obligation identity')
            exact(entry['canonical_row_sha256'], sha(json.dumps(original, sort_keys=True, separators=(',', ':')).encode()), 'full original obligation preserved')
    for p in gaps['qualified_proofs']:
        exact(p['status'], 'required-not-proven', 'all native proofs pending')
        exact(p['actual_evidence'], None, 'no invented native evidence')
    for case in gaps['native_case_templates']:
        exact(case['status'], 'required-not-run', 'all native cases unrun')
        exact(case['actual_result'], None, 'no native result')
    exact(sum(c['platform'] == 'Slackware-15.0' for c in gaps['native_case_templates']), 26, '15.0 cases')
    exact(sum(c['platform'] == 'Slackware-current' for c in gaps['native_case_templates']), 26, 'current cases')
    return conditions

def validate_checkpoint(confirmation, receipt):
    raw = receipt['text'].encode('utf-8')
    exact(receipt['encoding'], 'utf8-json-text', 'receipt encoding')
    exact(len(raw), receipt['original_display_size_bytes'], 'full receipt size')
    exact(sha(raw), receipt['original_display_sha256'], 'full receipt SHA')
    exact(sha(raw), confirmation['evidence_sha256'], 'confirmation binds receipt')
    exact(len(raw), confirmation['evidence_size_bytes'], 'confirmation size')
    exact(confirmation['step'], 338, 'accepted step338')
    exact(confirmation['commit_prefix'], '0bdf964', 'reported accepted prefix')
    exact(confirmation['commit_full'], None, 'full ID not independently known')
    exact(confirmation['acceptance_result'], 'PASS (364 passes, 0 failures)', 'complete acceptance')
    for key in ('strong_safe_pause', 'user_application_completed', 'user_harness_completed', 'user_commit_and_push_completed', 'user_head_matches_origin', 'user_worktree_clean', 'complete_ordered_return_matches_prepared_and_installed', 'confirmation_external_to_immutable_repository'):
        exact(confirmation[key], True, 'complete original acceptance ' + key)
    for key in ('runtime_authority', 'operational_readiness', 'operational_conformance', 'phase1_matrix_complete', 'kernel_package_edge_complete', 'phase2_open', 'machine_action_required', 'controller_action_required', 'historical_binding_or_authority_reuse_allowed'):
        exact(confirmation[key], False, 'no native authority from receipt')
    exact(confirmation['actual_host_state'], 'unobserved-not-claimed-absent', 'host unobserved')
    lines = receipt['text'].splitlines()
    exact(sum(x.startswith('PASS: ') for x in lines), 364, 'complete ordered receipt')
    exact(lines.count('Result: PASS (364 passes, 0 failures)'), 1, 'one acceptance summary')
    message = 'Phase 1 step 338: freeze scoped candidate artifacts and conditional safe pause'
    exact(lines.count('0bdf964 (HEAD -> main, origin/main, origin/HEAD) ' + message), 2, 'matching reported heads')
    if '6dfdaed..0bdf964  main -> main' not in receipt['text']:
        raise ValueError('successful reported push missing')
    return True

def verify(root):
    root = Path(root).absolute()
    if not root.is_dir() or root.resolve() != root:
        raise ValueError('unsafe repository root')
    for rel, digest in OWN_HASHES.items():
        exact(sha(safe_path(root, rel).read_bytes()), digest, 'current input SHA: ' + rel)
    load = lambda suffix: json.loads(safe_path(root, FIXTURE + BASE + suffix).read_bytes())
    policy = load('-policy.json')
    history = {}
    for rel, digest in policy['baseline_sha256_bindings'].items():
        raw = safe_path(root, rel).read_bytes()
        if rel == 'CHANGELOG.md':
            if len(raw) <= policy['accepted_changelog_size']:
                raise ValueError('missing additive339 changelog')
            raw = raw[-policy['accepted_changelog_size']:]
        exact(sha(raw), digest, 'accepted338 source SHA: ' + rel)
        history[rel] = raw
    exact(len(history), 1629, 'all accepted338 files')
    retained = load('-retained-obligations.json')
    conditions = validate_retained(retained, history)
    validate_plan(load('-plan.json'), conditions)
    validate_checkpoint(load('-checkpoint-confirmation.json'), load('-step338-user-acceptance.json'))
    return history

def main(argv):
    if argv == ['--help']:
        print('Repository-only planning check: --check REPOSITORY. No runtime authority.')
        return 0
    if len(argv) != 2 or argv[0] != '--check' or not argv[1]:
        print('Usage: verifier --check REPOSITORY', file=sys.stderr)
        return 2
    try:
        verify(argv[1])
    except (ValueError, KeyError, TypeError, OSError) as error:
        print('ERROR: ' + str(error), file=sys.stderr)
        return 1
    print('step339_repository_planning_status\tPASS')
    print('last_confirmed_strong_safe_pause_step\t338')
    print('conditional_next_pause_step\t348')
    print('native_cases_run\t0')
    print('native_proofs_added\t0')
    print('runtime_authority\tno')
    return 0

if __name__ == '__main__':
    raise SystemExit(main(sys.argv[1:]))
