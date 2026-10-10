#!/usr/bin/env python3
"""Verify the repository-only comparator plan; never collect or execute evidence."""
from pathlib import Path
import hashlib
import json
import sys

BASE = 'phase-1-kernel-package-edge-runtime-transaction-remediation-local-source-v4-operational-offline-evidence-comparator-resume-planning-review'
FIXTURE = 'tests/fixtures/reference/acceptance/phase-1/'
OWN_HASHES = {'docs/reference/phase-1-kernel-package-edge-runtime-transaction-remediation-local-source-v4-operational-offline-evidence-comparator-resume-planning-review.md': '13ca1cb88705ef4154eb814b2eb134d7e07bed134b77a53bb40f657833aa9308', 'tests/fixtures/reference/acceptance/phase-1/phase-1-kernel-package-edge-runtime-transaction-remediation-local-source-v4-operational-offline-evidence-comparator-resume-planning-review-checkpoint-confirmation.json': '36ab008dbaa9fdf6a98d188fab18017d2893321ed1417818be7d624705db41b0', 'tests/fixtures/reference/acceptance/phase-1/phase-1-kernel-package-edge-runtime-transaction-remediation-local-source-v4-operational-offline-evidence-comparator-resume-planning-review-plan.json': '61b73dfd86b26b53fe5d6a18cd3253bbb6c17e11795c7a905e748ea83ba54a65', 'tests/fixtures/reference/acceptance/phase-1/phase-1-kernel-package-edge-runtime-transaction-remediation-local-source-v4-operational-offline-evidence-comparator-resume-planning-review-policy.json': 'c04ca6b1e322f96611213a0e7988b876e1d6151ee4844c18cb5b0d60a5eca55b', 'tests/fixtures/reference/acceptance/phase-1/phase-1-kernel-package-edge-runtime-transaction-remediation-local-source-v4-operational-offline-evidence-comparator-resume-planning-review-retained-obligations.json': '41264407246ab282c402cdb7cf938cd60098a6118e1b289fdb4cdd1c306b664f', 'tests/fixtures/reference/acceptance/phase-1/phase-1-kernel-package-edge-runtime-transaction-remediation-local-source-v4-operational-offline-evidence-comparator-resume-planning-review-step348-user-acceptance.json': 'a8d02846bf6f0f0b4a7cd36df6019b104256b7433b06a22e971d2ab35e66193e', 'tests/fixtures/reference/acceptance/phase-1/phase-1-kernel-package-edge-runtime-transaction-remediation-local-source-v4-operational-offline-evidence-comparator-resume-planning-review-roadmap.tsv': 'eb1eaec72ae66ddb00868e705a1675da53f27f3ba6d38a1679627c04821851f5'}
COUNTS = {'capabilities': 7, 'cross_obligations': 10, 'domains': 30, 'macro_cuts': 81, 'macro_relations': 95, 'native_cases': 52, 'native_gaps': 16, 'native_proofs': 46, 'nominal_interfaces': 26, 'nominal_types': 35, 'owned_microsteps': 9, 'phases': 27, 'rights_windows': 9}
PLAN_KEYS = ['actual_dynamic_graph_complete', 'actual_host_state', 'actual_independent_oracle_selected', 'actual_live_bindings', 'actual_native_collector_selected', 'actual_native_refinement_complete', 'actual_operational_implementation_frozen', 'automatic_native_proof_promotion', 'comparator_execution_scope', 'comparator_implemented', 'comparison_match_is_native_proof', 'comparison_result_boundary', 'compatibility_claim', 'compatibility_targets', 'conditional_pause_step', 'controller_action_required', 'counts', 'historical_bindings_reusable', 'independence_boundary', 'kernel_package_edge_complete', 'last_confirmed_strong_safe_pause_step', 'later_preparation_requires_complete_predecessor_return', 'machine_action_required', 'model_or_fixture_is_native_evidence', 'native_cases_run', 'native_effect_requests_allowed', 'native_ingestion_boundary', 'native_proofs_added', 'new_user_request', 'operational_conformance', 'operational_readiness', 'pause_conditions', 'phase1_matrix_complete', 'phase2_open', 'preferred_step_range', 'production_entry_closed', 'provenance_labels_establish_independence', 'route', 'runtime_authority', 'schema', 'scope', 'separate_native_source_and_fresh_authority_required', 'step', 'stop_after_complete358_acceptance', 'strong_safe_pause', 'unchanged_offline_core_preserved', 'user_step349_checkpoint_confirmed']
FALSE_FIELDS = ['comparator_implemented', 'actual_independent_oracle_selected', 'actual_native_collector_selected', 'actual_native_refinement_complete', 'actual_operational_implementation_frozen', 'actual_dynamic_graph_complete', 'historical_bindings_reusable', 'native_effect_requests_allowed', 'model_or_fixture_is_native_evidence', 'comparison_match_is_native_proof', 'provenance_labels_establish_independence', 'automatic_native_proof_promotion', 'runtime_authority', 'operational_readiness', 'operational_conformance', 'phase1_matrix_complete', 'kernel_package_edge_complete', 'phase2_open', 'machine_action_required', 'controller_action_required', 'strong_safe_pause', 'user_step349_checkpoint_confirmed']
TRUE_FIELDS = ['new_user_request', 'production_entry_closed', 'later_preparation_requires_complete_predecessor_return', 'stop_after_complete358_acceptance', 'unchanged_offline_core_preserved', 'separate_native_source_and_fresh_authority_required']
ROUTE = [{'deliverable': 'Bind confirmed348, unchanged offline core and all native obligations; plan a repository-only evidence comparator with no native collector or runner.', 'entry_requires_confirmed_step': 348, 'runtime_authorized': False, 'stage': 'resume-plan', 'status': 'current-preparation', 'step': 349}, {'deliverable': 'Define a closed bounded data envelope and raw-artifact inventory with exact byte sizes, digests and platform/run/original identity fields; reject unsafe paths, archives and unknown fields without executing content.', 'entry_requires_confirmed_step': 349, 'runtime_authorized': False, 'stage': 'bounded-evidence-schema', 'status': 'future-repository-work', 'step': 350}, {'deliverable': 'Define separately reviewed literal expected vectors and provenance requirements; subject output and frozen model reducers cannot generate the sole oracle or attest independence.', 'entry_requires_confirmed_step': 350, 'runtime_authorized': False, 'stage': 'independent-expectation-contract', 'status': 'future-repository-work', 'step': 351}, {'deliverable': 'Implement non-dispatching byte ingestion and immutable observation indexing; distinguish missing, unknown, contradictory and captured data while preserving raw bytes and original identities.', 'entry_requires_confirmed_step': 351, 'runtime_authorized': False, 'stage': 'captured-observation-index', 'status': 'future-repository-work', 'step': 352}, {'deliverable': 'Compare complete independently supplied selector, raw exit/status, original pin and target/owned effect vectors; retain empty install-new versus mandatory one-target upgrade semantics and unexpected effects.', 'entry_requires_confirmed_step': 352, 'runtime_authorized': False, 'stage': 'selector-and-effect-comparison', 'status': 'future-repository-work', 'step': 353}, {'deliverable': 'Compare original failure, child/guard observations, finite pre-spent recovery rights/budget, exact original restoration or unchanged verification and separately pending owned/target obligations.', 'entry_requires_confirmed_step': 353, 'runtime_authorized': False, 'stage': 'recovery-and-obligation-comparison', 'status': 'future-repository-work', 'step': 354}, {'deliverable': 'Compare captured-data-only publication observations, separate record/last receipt durability and trusted origin/handoff, preserving unknown partial artifacts and no replay conclusions.', 'entry_requires_confirmed_step': 354, 'runtime_authorized': False, 'stage': 'publication-and-receipt-comparison', 'status': 'future-repository-work', 'step': 355}, {'deliverable': 'Exercise missing/truncated/forged/cross-platform/cross-run/reordered evidence and contradictory fault controls using separately authored expected diagnostics; private fixtures never satisfy native case templates.', 'entry_requires_confirmed_step': 355, 'runtime_authorized': False, 'stage': 'adversarial-comparator-controls', 'status': 'future-repository-work', 'step': 356}, {'deliverable': 'Reconcile comparator coverage against every original proof, case, phase, interface, domain, window, capability, obligation and cut; retain unselected collector/verifier/native refinement and both-platform gaps.', 'entry_requires_confirmed_step': 356, 'runtime_authorized': False, 'stage': 'comparator-contract-gap-reconciliation', 'status': 'future-repository-work', 'step': 357}, {'deliverable': 'Freeze the tested comparator sources and unresolved native gaps; externally confirm only the repository349-358 pause after complete user acceptance, then stop the batch.', 'entry_requires_confirmed_step': 357, 'runtime_authorized': False, 'stage': 'comparator-freeze-and-pause', 'status': 'future-repository-work', 'step': 358}]
SCOPE = 'repository-offline-evidence-comparator-workstream349-358-only'


def sha(raw):
    return hashlib.sha256(raw).hexdigest()


def exact(value, expected, label):
    # Recursively preserve JSON types, including bool versus int in nested rows.
    if type(value) is not type(expected):
        raise ValueError(label)
    if type(expected) is dict:
        if value.keys() != expected.keys():
            raise ValueError(label)
        for key in expected:
            exact(value[key], expected[key], label + '/' + key)
    elif type(expected) is list:
        if len(value) != len(expected):
            raise ValueError(label)
        for i, (left, right) in enumerate(zip(value, expected)):
            exact(left, right, label + '/' + str(i))
    elif value != expected:
        raise ValueError(label)


def safe_path(root, relative):
    if type(relative) is not str or not relative or '\\' in relative:
        raise ValueError('invalid repository path')
    if relative.startswith('/') or any(p in ('', '.', '..') for p in relative.split('/')):
        raise ValueError('unsafe repository path')
    p = root / relative
    if p.is_symlink() or p.resolve() != p.absolute() or not p.is_file():
        raise ValueError('missing or unsafe repository file: ' + relative)
    return p


def index_rows(value):
    if type(value) not in (list, dict):
        raise ValueError('invalid full normative register')
    rows = list(enumerate(value)) if type(value) is list else list(value.items())
    return [dict(position=i, key=key, canonical_row_sha256=sha(json.dumps(row, sort_keys=True, separators=(',', ':')).encode()))
            for i, (key, row) in enumerate(rows)]


def validate_retained(retained, history, policy):
    exact(sorted(retained), ['counts', 'frozen_artifact_registry339_347', 'model_modules', 'normative_rule', 'original_pause_conditions', 'registers', 'schema', 'source_bindings', 'step'], 'closed retained schema')
    exact(retained['schema'], 1, 'retained schema')
    exact(retained['step'], 349, 'retained step')
    exact(retained['counts'], COUNTS, 'retained obligation counts')
    exact(retained['source_bindings'], policy['source_bindings'], 'all four normative sources')
    sources = {}
    for role, binding in retained['source_bindings'].items():
        raw = history[binding['path']]
        exact(sha(raw), binding['sha256'], 'full source content: ' + role)
        sources[role] = json.loads(raw)
    freeze = sources['freeze348']; gaps = sources['gaps348']; old = sources['reconciliation347']; oracle = sources['oracle335']
    for name, step in [('freeze348',348),('gaps348',348),('reconciliation347',347),('oracle335',335)]:
        exact(sources[name]['step'], step, 'original source step')
    full = old['retained_full_normative_rows']
    expected = {'reconciliation347/' + k: index_rows(v) for k, v in full.items()}
    for k in ['qualified_proofs', 'native_case_templates', 'native_gap_rows', 'macro_cut_obligations', 'owned_stage7_microsteps']:
        expected['gaps348/' + k] = index_rows(gaps[k])
    for k in ['cases', 'evidence_groups', 'independence_contract', 'inherited_source_evidence_gates']:
        expected['oracle335/' + k] = index_rows(oracle[k])
    exact(retained['registers'], expected, 'every complete ordered normative row')
    exact(retained['model_modules'], freeze['model_modules'], 'seven unchanged core modules')
    exact(retained['frozen_artifact_registry339_347'], freeze['frozen_artifact_registry339_347'], '81 unchanged frozen inputs')
    for binding in list(retained['model_modules'].values()) + retained['frozen_artifact_registry339_347'] + list(full['exact_contract_bindings'].values()):
        exact(sha(history[binding['path']]), binding['sha256'], 'unchanged source module/input/contract')
    exact(len(retained['model_modules']), 7, 'seven modules')
    exact(len(retained['frozen_artifact_registry339_347']), 81, '81 inputs')
    exact(retained['original_pause_conditions'], freeze['original_pause_conditions'], 'all original nine pause conditions')
    exact(len(retained['original_pause_conditions']), 9, 'nine pause conditions')
    for key, field in [('native_proofs','qualified_proofs'),('native_cases','native_case_templates'),('native_gaps','native_gap_rows'),('macro_cuts','macro_cut_obligations'),('owned_microsteps','owned_stage7_microsteps')]:
        exact(len(gaps[field]), COUNTS[key], 'complete native register ' + key)
    for row in gaps['qualified_proofs']:
        exact(row['status'], 'required-not-proven', 'native proof remains pending')
        exact(row['actual_evidence'], None, 'no native proof evidence')
    for row in gaps['native_case_templates']:
        exact(row['status'], 'required-not-run', 'native case remains unrun')
        exact(row['actual_result'], None, 'no native case result')
    for platform in ['Slackware-15.0','Slackware-current']:
        exact(sum(r['platform'] == platform for r in gaps['native_case_templates']), 26, 'separate 26 native cases')
    return sources


def validate_plan(plan, sources):
    exact(sorted(plan), PLAN_KEYS, 'closed planning schema')
    for key, value in [('schema',1),('step',349),('scope',SCOPE),('last_confirmed_strong_safe_pause_step',348),('preferred_step_range',[349,358]),('conditional_pause_step',358),('counts',COUNTS),('actual_live_bindings',None),('actual_host_state','unobserved-not-claimed-absent'),('compatibility_targets',['Slackware-15.0','Slackware-current']),('compatibility_claim','not-tested-natively'),('comparator_execution_scope','repository-captured-data-comparison-only'),('native_cases_run',0),('native_proofs_added',0)]:
        exact(plan[key], value, 'planning boundary ' + key)
    for key in FALSE_FIELDS:
        exact(plan[key], False, 'no native/actual promotion: ' + key)
    for key in TRUE_FIELDS:
        exact(plan[key], True, 'required batch boundary: ' + key)
    exact(plan['route'], ROUTE, 'ten staged deliverables and full predecessor gates')
    exact(plan['pause_conditions'], sources['freeze348']['original_pause_conditions'], 'all original pause conditions')
    exact(plan['independence_boundary'], sources['oracle335']['independence_contract'], 'full original independent oracle contract')
    for field in ['comparison_result_boundary','native_ingestion_boundary']:
        if type(plan[field]) is not str or len(plan[field]) < 100:
            raise ValueError('missing comparison or ingestion boundary')
    return True


def validate_return(confirmation, receipt, policy):
    exact(sorted(receipt), ['encoding', 'ordered_output_normalization', 'original_display_sha256', 'original_display_size_bytes', 'text'], 'closed original receipt')
    exact(receipt['encoding'], 'utf8-json-text', 'original encoding')
    exact(receipt['ordered_output_normalization'], 'none', 'no normalization')
    if type(receipt['text']) is not str:
        raise ValueError('missing complete receipt')
    raw = receipt['text'].encode('utf-8')
    exact(len(raw), 32858, 'complete original348 size')
    exact(sha(raw), 'ba0144843d15c4d0df9ae18e5cd50b76c016da643698d1a643175ef340c2c340', 'complete original348 SHA')
    exact(receipt['original_display_size_bytes'], len(raw), 'receipt size')
    exact(receipt['original_display_sha256'], sha(raw), 'receipt SHA')
    exact(confirmation['evidence_size_bytes'], len(raw), 'confirmation size')
    exact(confirmation['evidence_sha256'], sha(raw), 'confirmation SHA')
    for key, value in [('step',348),('commit_prefix','83ae543'),('commit_full',None),('accepted_repository_file_count',1719),('acceptance_result','PASS (200 passes, 0 failures)'),('scope','repository-offline-transition-core-workstream339-348-only'),('observation_basis','complete-original-user-return-and-exact-checked-source-not-independent-host-or-GitHub-inspection'),('actual_host_state','unobserved-not-claimed-absent'),('actual_live_bindings',None),('next_authorized_stage',None),('required_not_proven_native_proofs',46),('required_not_run_native_cases',52),('unresolved_native_gaps',16)]:
        exact(confirmation[key], value, 'accepted348 fact ' + key)
    for key in ['strong_safe_pause','user_application_completed','user_harness_completed','user_commit_and_push_completed','user_head_matches_origin','user_worktree_clean','complete_ordered_return_matches_prepared_and_installed','confirmation_external_to_immutable_repository','batch_complete']:
        exact(confirmation[key], True, 'complete accepted348 return ' + key)
    for key in ['runtime_authority','new_runtime_work_authorized','operational_readiness','operational_conformance','phase1_matrix_complete','kernel_package_edge_complete','phase2_open','machine_action_required','controller_action_required','historical_binding_or_authority_reuse_allowed','historical_prepared_flags_rewritten','actual_operational_implementation_frozen','actual_native_refinement_complete','actual_dynamic_graph_complete','actual_independent_oracle_selected']:
        exact(confirmation[key], False, 'no native/actual promotion from old receipt ' + key)
    exact(len(confirmation['pause_conditions']),9,'nine accepted conditions')
    for i,row in enumerate(confirmation['pause_conditions']):
        exact(row['position'],i,'ordered accepted pause condition')
        exact(row['actual_native_evidence'],None,'no native pause evidence')
        exact(row['native_proof_promoted'],False,'no native pause promotion')
    lines = receipt['text'].splitlines()
    labels = [x for x in lines if x.startswith('PASS: ')]
    exact(labels, policy['expected_predecessor_labels'], 'complete200 ordered original labels')
    exact(lines.count(policy['expected_predecessor_result']),1,'one complete200 summary')
    message = 'Phase 1 step 348: freeze offline core and conditional strong safe pause'
    exact(lines.count('[main 83ae543] '+message),1,'exact original commit')
    exact(lines.count(' 10 files changed, 22012 insertions(+)'),1,'exact original ten-file scope')
    exact(sum(x.startswith(' create mode 100644 ') for x in lines),9,'nine original created paths')
    exact(lines.count('83ae543 (HEAD -> main, origin/main, origin/HEAD) '+message),2,'matching final reported heads')
    if '   fed2808..83ae543  main -> main' not in lines:
        raise ValueError('successful original push missing')
    return True


def verify(root):
    root = Path(root).absolute()
    if not root.is_dir() or root.resolve() != root:
        raise ValueError('unsafe repository root')
    for relative, digest in OWN_HASHES.items():
        exact(sha(safe_path(root, relative).read_bytes()), digest, 'current planning input SHA')
    load = lambda tail: json.loads(safe_path(root, FIXTURE+BASE+'-'+tail+'.json').read_bytes())
    policy = load('policy')
    history = {}
    for relative, digest in policy['baseline_sha256_bindings'].items():
        raw = safe_path(root, relative).read_bytes()
        if relative == 'CHANGELOG.md':
            if len(raw) <= policy['accepted_changelog_size']:
                raise ValueError('missing additive349 CHANGELOG')
            raw = raw[-policy['accepted_changelog_size']:]
        exact(sha(raw), digest, 'accepted348 bytes ' + relative)
        history[relative] = raw
    exact(len(history), 1719, 'all1719 accepted files')
    sources = validate_retained(load('retained-obligations'), history, policy)
    validate_plan(load('plan'), sources)
    validate_return(load('checkpoint-confirmation'), load('step348-user-acceptance'), policy)
    return history


def main(argv):
    if argv == ['--help']:
        print('Repository-only planning check: --check REPOSITORY. No evidence execution or native authority.')
        return 0
    if len(argv) != 2 or argv[0] != '--check' or not argv[1]:
        print('Usage: verifier --check REPOSITORY', file=sys.stderr)
        return 2
    try:
        verify(argv[1])
    except (ValueError, KeyError, TypeError, OSError) as error:
        print('ERROR: '+str(error), file=sys.stderr)
        return 1
    print('step349_repository_planning_status\tPASS')
    print('last_confirmed_strong_safe_pause_step\t348')
    print('conditional_next_pause_step\t358')
    print('native_cases_run\t0')
    print('native_proofs_added\t0')
    print('runtime_authority\tno')
    return 0


if __name__ == '__main__':
    raise SystemExit(main(sys.argv[1:]))
