#!/usr/bin/env python3
"""Validate repository-only successor design planning; accept supplied data only."""
import hashlib
import json
import re

def sha(raw):
    return hashlib.sha256(raw).hexdigest()

def canonical(value):
    return sha(json.dumps(value, sort_keys=True, separators=(',', ':'), ensure_ascii=True).encode())

def exact(value, expected, label):
    if type(value) is not type(expected) or (value != expected if isinstance(value, set) else canonical(value) != canonical(expected)):
        raise ValueError(label)
    return True

POLICY_SHA = '26acf67b8084bf23db0893d871b7ad8fe2683dbc4bfe575671cafb2a26ab40d9'
CONFIRMATION_SHA = '73770570bb69cf40e858027edb3b900f14309814a643801be1c62a01f630bb31'
CONDITIONS_SHA = '1c6271b85f690263b9785c70a1d654b4a958c3040e90679347a0c85bda8db4c3'
BOUNDARIES = {'C_port_open': False, 'actual_global_host_closure': False, 'actual_host_state': 'unobserved-not-claimed-absent', 'actual_live_bindings': None, 'actual_native_refinement_complete': False, 'actual_successor_selected': False, 'controller_action_required': False, 'execution_authorized': False, 'kernel_package_edge_complete': False, 'machine_action_required': False, 'native_cases_run': 0, 'native_components_selected': False, 'native_graph_complete': False, 'native_proofs_added': 0, 'operational_conformance': False, 'operational_readiness': False, 'phase1_matrix_complete': False, 'phase2_open': False, 'production_entry_closed': True, 'reference_v1_frozen': False, 'runtime_authority': False, 'strong_safe_pause': False, 'version1_schema_frozen': False, 'last_confirmed_strong_safe_pause_step': 368, 'historical_binding_or_authority_reuse_allowed': False, 'current_step_strong_safe_pause': False, 'later_current_refresh_invalidates_repository_only_pause': False, 'target_machine_actions_authorized': False, 'design_proposal_is_operational_implementation': False}
STAGES = [{'step': 369, 'stage': 'resume-plan', 'deliverable': 'Bind accepted368, open this finite design review batch, retain every native blocker.', 'primary_gap_ids': [], 'entry_requires_confirmed_step': 368, 'runtime_authorized': False, 'native_proof_discharge_allowed': False, 'C_development_authorized': False}, {'step': 370, 'stage': 'successor-source-and-effect-design', 'deliverable': 'Draft the reference successor responsibilities, complete graph admission rules, dependency consumption and explicit exclusion obligations; retain unresolved edges.', 'primary_gap_ids': ['actual-successor-entry-and-transitive-graph', 'versioned-real-backend-and-full-selector', 'package-hooks-source-archive-and-helper-consumption'], 'entry_requires_confirmed_step': 369, 'runtime_authorized': False, 'native_proof_discharge_allowed': False, 'C_development_authorized': False}, {'step': 371, 'stage': 'issuer-admission-and-launch-design', 'deliverable': 'Draft separate issuer trust, authenticated original handoff, durable claim/quarantine and launch pre-spend/supervision; expose unknown-outcome cuts.', 'primary_gap_ids': ['issuer-authentication-key-provenance', 'linearizable-durable-claim-and-quarantine', 'durable-launch-spend-and-supervision'], 'entry_requires_confirmed_step': 370, 'runtime_authorized': False, 'native_proof_discharge_allowed': False, 'C_development_authorized': False}, {'step': 372, 'stage': 'native-platform-primitives-design', 'deliverable': 'Compare proposed containment, FD, time/revocation, writer/alias and durability primitives separately for both platforms; label all unverified properties.', 'primary_gap_ids': ['offline-bootstrap-and-FD-namespace-containment', 'native-time-revocation-fence', 'native-writer-object-alias-and-lifetime-exclusion'], 'entry_requires_confirmed_step': 371, 'runtime_authorized': False, 'native_proof_discharge_allowed': False, 'C_development_authorized': False}, {'step': 373, 'stage': 'baseline-owned-recovery-design', 'deliverable': 'Draft fresh original capture, pinned raw input, approved deltas, owned backup microsteps and finite same-attempt recovery including known unchanged-target paths.', 'primary_gap_ids': ['fresh-original-baseline-and-approved-deltas', 'owned-backup-binding-and-child-recovery-primitives', 'bounded-clock-budget-and-same-attempt-recovery'], 'entry_requires_confirmed_step': 372, 'runtime_authorized': False, 'native_proof_discharge_allowed': False, 'C_development_authorized': False}, {'step': 374, 'stage': 'closure-and-publication-design', 'deliverable': 'Draft independent invariant/child/target closure before release, captured-data publication and separate no-replace record/final receipt durability.', 'primary_gap_ids': ['target-closure-before-release', 'independent-publication-last-receipt-durability-and-origin'], 'entry_requires_confirmed_step': 373, 'runtime_authorized': False, 'native_proof_discharge_allowed': False, 'C_development_authorized': False}, {'step': 375, 'stage': 'independent-evidence-and-oracle-design', 'deliverable': 'Draft independent collector/verifier/expectation trust and full raw provenance, two-platform identity and positive/negative fault-control requirements.', 'primary_gap_ids': ['independent-two-platform-oracle-and-fault-observations'], 'entry_requires_confirmed_step': 374, 'runtime_authorized': False, 'native_proof_discharge_allowed': False, 'C_development_authorized': False}, {'step': 376, 'stage': 'native-refinement-and-case-design', 'deliverable': 'Draft proposed micro-event/crash/concurrency mappings to every original proof, case and raw group, with explicit unresolved feasibility; no native run.', 'primary_gap_ids': ['syscall-crash-concurrency-model-refinement'], 'entry_requires_confirmed_step': 375, 'runtime_authorized': False, 'native_proof_discharge_allowed': False, 'C_development_authorized': False}, {'step': 377, 'stage': 'design-readiness-and-readme-reconciliation', 'deliverable': 'Reconcile design findings, conflicts and blockers; review future authorization prerequisites without issuing authority; reconcile README current roadmap individually.', 'primary_gap_ids': [], 'entry_requires_confirmed_step': 376, 'runtime_authorized': False, 'native_proof_discharge_allowed': False, 'C_development_authorized': False}, {'step': 378, 'stage': 'design-freeze-and-conditional-pause', 'deliverable': 'Freeze complete design inputs and original scoped conditions; require final overlay/tests/exact commit/push/clean matching-head return then stop.', 'primary_gap_ids': [], 'entry_requires_confirmed_step': 377, 'runtime_authorized': False, 'native_proof_discharge_allowed': False, 'C_development_authorized': False}]

def validate_policy(policy):
    if canonical(policy) != POLICY_SHA:
        raise ValueError('frozen policy changed')
    return True

def validate_acceptance(confirmation, receipt, conditions, policy):
    validate_policy(policy)
    if canonical(confirmation) != CONFIRMATION_SHA or canonical(conditions) != CONDITIONS_SHA:
        raise ValueError('complete external confirmation changed')
    raw = receipt['text'].encode('utf-8')
    expected = {'schema':1, 'step':368, 'sha256':confirmation['receipt_sha256'],
        'size_bytes':confirmation['receipt_size_bytes'], 'normalization':'none',
        'capture_basis':'complete-uploaded-user-message-UTF8-bytes;not-independent-terminal-byte-capture'}
    exact({k:v for k,v in receipt.items() if k != 'text'}, expected, 'receipt metadata')
    exact(sha(raw), expected['sha256'], 'complete received message SHA')
    exact(len(raw), expected['size_bytes'], 'complete received message length')
    text = receipt['text']; contract = policy['accepted368_contract']
    exact([s for s in text.splitlines() if s.startswith('PASS: ')],
        contract['expected_ordered_PASS_labels'], 'all167 ordered accepted PASS labels')
    for label in ('expected_zero_failure_summary', 'expected_overlay_status',
                  'expected_commit_scope_status', 'expected_commit_stats'):
        if text.count(contract[label]) != 1:
            raise ValueError('single accepted occurrence required: ' + label)
    message = contract['expected_commit_message']
    if text.count('[main 030acb8] ' + message) != 1 or text.count('06ce1a3..030acb8  main -> main') != 1:
        raise ValueError('accepted commit or successful push missing')
    exact(re.findall(r'^ create mode 100644 (.+)$', text, re.M),
        contract['expected_created_paths'], 'all eight created paths')
    head = '030acb8 (HEAD -> main, origin/main, origin/HEAD) ' + message
    if text.count(head) != 2 or not text.endswith(head+'\n'+head+'\npromano@pc-arch ~/Descargas $ \n'):
        raise ValueError('complete reported clean status and matching-head ending')
    return True

def validate_inputs(inputs, source_bytes, readme, policy):
    validate_policy(policy)
    exact(set(inputs), set(policy['input_paths']), 'all complete frozen inputs')
    for key, value in inputs.items():
        exact(canonical(value), policy['input_canonical_sha256'][key], 'full frozen input ' + key)
    exact(set(source_bytes), {row['path'] for row in policy['source_roots']}, 'four exact review roots')
    for row in policy['source_roots']:
        raw = source_bytes[row['path']]
        if type(raw) is not bytes or sha(raw) != row['sha256'] or len(raw) != row['size_bytes']:
            raise ValueError('original review source bytes changed')
    if type(readme) is not bytes or sha(readme) != policy['readme_at_entry_sha256']:
        raise ValueError('accepted README changed before377')
    freeze = inputs['freeze']; prerequisites = inputs['prerequisites']; pause = inputs['pause']
    for key in ('full_original_native_gap_rows348', 'full_qualified_proof_rows347',
                'full_native_case_rows347', 'full_independent_raw_groups335'):
        exact(prerequisites[key], freeze[key], 'complete original obligations agree: ' + key)
    if len(pause['conditions']) != 9 or not policy['accepted368_contract']['must_retain_full_original_conditions']:
        raise ValueError('all original pause conditions required')
    return True

def validate_plan(plan, inputs, policy):
    validate_policy(policy)
    if canonical(plan) != policy['plan_canonical_sha256']:
        raise ValueError('authored finite design plan changed')
    exact(plan['boundaries'], BOUNDARIES, 'all repository and native gates')
    exact(plan['roadmap'], STAGES, 'complete finite ordered roadmap')
    exact(plan['full_requirement_input_paths'], policy['input_paths'], 'full requirements retained')
    exact(plan['future_deliverables365'], inputs['prerequisites']['future_review_deliverables'], 'all eight original future reviews')
    assigned = [gap for row in plan['roadmap'] for gap in row['primary_gap_ids']]
    exact(sorted(assigned), sorted(policy['expected_gap_ids']), 'all16 primary backlog assignments')
    if len(assigned) != len(set(assigned)):
        raise ValueError('duplicated primary gap assignment')
    for step, row in zip(range(369, 379), plan['roadmap']):
        if type(row['step']) is not int or row['step'] != step or row['entry_requires_confirmed_step'] != step-1:
            raise ValueError('successor entry requires complete predecessor acceptance')
    return True

def review(plan, confirmation, receipt, conditions, inputs, source_bytes, readme, policy):
    validate_acceptance(confirmation, receipt, conditions, policy)
    validate_inputs(inputs, source_bytes, readme, policy)
    validate_plan(plan, inputs, policy)
    # Return independent copies; mutation never changes frozen expectations or caller data.
    return json.loads(json.dumps({'schema':1, 'step':369, 'scope':plan['scope'],
        'state':'prepared-user-acceptance-pending', 'boundaries':BOUNDARIES,
        'roadmap':STAGES, 'all_full_original_requirements_normative_at_every_stage':True,
        'full_original_native_gap_rows348':inputs['freeze']['full_original_native_gap_rows348'],
        'original_pause_conditions':inputs['pause']['conditions'],
        'actual_native_components_selected':False, 'native_proofs_added':0,
        'native_cases_run':0, 'runtime_authority':False,
        'actual_strong_safe_pause_confirmed':False, 'no_automatic379':True}))
