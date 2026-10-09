#!/usr/bin/env python3
"""Reconcile pinned offline source and full native obligations, without dispatch."""
from pathlib import Path
import ast
import hashlib
import json
import re
import sys

BASE = 'phase-1-kernel-package-edge-runtime-transaction-remediation-local-source-v4-operational-offline-contract-refinement-reconciliation-review'
PREFIX = 'phase-1-kernel-package-edge-runtime-transaction-remediation-local-source-v4-operational-'
FIXTURE = 'tests/fixtures/reference/acceptance/phase-1/'
OWN_HASHES = {'docs/reference/phase-1-kernel-package-edge-runtime-transaction-remediation-local-source-v4-operational-offline-contract-refinement-reconciliation-review.md': 'cb659b3cc5b9044e695210c1308e17d65e2452507933120b769dfe2afcd295d8', 'tests/fixtures/reference/acceptance/phase-1/phase-1-kernel-package-edge-runtime-transaction-remediation-local-source-v4-operational-offline-contract-refinement-reconciliation-review-checkpoint-confirmation.json': '69f6635d2ca4cc9c92841403c6f2f5e521db82fb9bbd5b766cb9fe4a2be9e701', 'tests/fixtures/reference/acceptance/phase-1/phase-1-kernel-package-edge-runtime-transaction-remediation-local-source-v4-operational-offline-contract-refinement-reconciliation-review-native-gap-register.json': 'a33e82f84c5933f297aa29663b2afe172cdad3b4683d2777841bf5e7ed7b6573', 'tests/fixtures/reference/acceptance/phase-1/phase-1-kernel-package-edge-runtime-transaction-remediation-local-source-v4-operational-offline-contract-refinement-reconciliation-review-policy.json': '2ca6585a7a23b969bbe89e7cccefb9100fdc3e4e137bb446e9e2405957bea26f', 'tests/fixtures/reference/acceptance/phase-1/phase-1-kernel-package-edge-runtime-transaction-remediation-local-source-v4-operational-offline-contract-refinement-reconciliation-review-reconciliation.json': '6e06742cfabe2da0406a84c628a824efe77c322eb6767ac433b6ab8f51c5e1ef', 'tests/fixtures/reference/acceptance/phase-1/phase-1-kernel-package-edge-runtime-transaction-remediation-local-source-v4-operational-offline-contract-refinement-reconciliation-review-rule-map.json': '2171f0a406de9bb078591afb311f4eb1d97d2cbc550d43ed0a4719742ffc55c1', 'tests/fixtures/reference/acceptance/phase-1/phase-1-kernel-package-edge-runtime-transaction-remediation-local-source-v4-operational-offline-contract-refinement-reconciliation-review-step346-user-acceptance.json': 'e86a388582885b249aef0a1ba5fd3b641a72d0979459edbc7657f1f7b0cab3c1'}
ADDITION_SHA = '23c154c9aad812c207c852665f2ca1ce131adcfc8f62eb84eccedde12cc8fff9'
FROZEN_FIELDS = ('exact_contract_bindings', 'exact_contract_views',
 'effect_domain_reconciliation', 'all95_macro_design_relations',
 'all27_phase_boundaries', 'all26_nominal_interfaces', 'all35_nominal_types',
 'qualified_proof_reconciliation', 'authority_window_reconciliation',
 'seven_capability_reconciliation', 'ten_cross_obligation_reconciliation')
GAP_FIELDS = ('macro_cut_obligations', 'owned_stage7_microsteps',
 'native_case_templates', 'native_gap_register', 'original_phase_and_bootstrap_contract')


def sha(value):
    return hashlib.sha256(value).hexdigest()


def exact(value, expected, label):
    # Canonical JSON comparison retains nested bool/int distinctions.
    if type(value) is not type(expected) or json.dumps(value, sort_keys=True) != json.dumps(expected, sort_keys=True):
        raise ValueError(label)


def safe_file(root, relative):
    if type(relative) is not str or not relative or '\\' in relative or any(x in ('', '.', '..') for x in relative.split('/')):
        raise ValueError('unsafe repository relative path')
    path = root / relative
    if not path.is_file() or path.is_symlink() or path.resolve() != path.absolute() or not path.resolve().is_relative_to(root):
        raise ValueError('unsafe source ' + relative)
    return path


def historical_json(history, tail):
    return json.loads(history[FIXTURE + PREFIX + tail + '.json'])


def extract_markdown_labels(text):
    summary = 'Result: PASS (616 passes, 0 failures)'
    if type(text) is not str or text.count(summary) != 1 or text.count('PASS: ') != 616:
        raise ValueError('complete singular616 Markdown return required')
    start, end = text.index('PASS: '), text.index(summary)
    return re.findall(r'PASS: .*?(?= PASS: |$)', text[start:end].strip())


def validate_return(confirmation, receipt, policy):
    raw = receipt['text'].encode('utf-8')
    exact(receipt['encoding'], 'utf8-original-markdown-text', 'original Markdown encoding')
    exact(receipt['original_bytes_normalized'], False, 'original bytes not rewritten')
    exact(len(raw), receipt['original_display_size_bytes'], 'original return size')
    exact(sha(raw), receipt['original_display_sha256'], 'original return digest')
    exact(sha(raw), confirmation['evidence_sha256'], 'confirmation receipt digest')
    exact(len(raw), confirmation['evidence_size_bytes'], 'confirmation receipt size')
    exact(extract_markdown_labels(receipt['text']), policy['accepted_ordered346_labels'], 'all616 literal ordered labels')
    exact(confirmation['step'], 346, 'accepted346')
    exact(confirmation['commit_prefix'], '038c896', 'reported346 prefix')
    exact(confirmation['commit_full'], None, 'full object ID unknown')
    exact(confirmation['acceptance_result'], 'PASS (616 passes, 0 failures)', 'complete616 summary')
    for key in ('complete_ordered_return_matches_prepared_and_installed', 'user_application_completed', 'user_harness_completed', 'user_commit_and_push_completed', 'user_head_matches_origin', 'user_worktree_clean', 'push_first_attempt_succeeded', 'production_entry_closed'):
        exact(confirmation[key], True, 'accepted report ' + key)
    for key in ('strong_safe_pause', 'runtime_authority', 'phase2_open', 'original_bytes_normalized'):
        exact(confirmation[key], False, 'no promotion ' + key)
    for key in ('actual_native_cases_run', 'actual_native_proofs_added'):
        exact(confirmation[key], 0, 'no native evidence ' + key)
    exact(confirmation['last_confirmed_strong_safe_pause_step'], 338, 'last confirmed pause338')
    exact(confirmation['actual_live_bindings'], None, 'no live binding')
    exact(confirmation['actual_host_state'], 'unobserved-not-claimed-absent', 'host unknown')
    exact(confirmation['push_attempt_count'], 1, 'single successful reported push')
    message = 'Phase 1 step 346: audit adversarial whole model sequences'
    exact(receipt['text'].count('038c896 (HEAD -> main, origin/main, origin/HEAD) ' + message), 2, 'matching reported HEAD and origin')
    exact(receipt['text'].count('[main 038c896] ' + message), 1, 'exact reported commit')
    exact(receipt['text'].count(' 10 files changed, 3900 insertions(+)'), 1, 'exact reported ten-path scope')
    if '8f6b3cd..038c896  main -> main' not in receipt['text'] or 'step346_overlay_application_status\tPASS' not in receipt['text']:
        raise ValueError('reported overlay and successful push required')
    # The Markdown exporter escaped dots in two displayed filenames. Accept only
    # each original expected path or its literal dot-escaped presentation form.
    displayed = re.findall(r' create mode 100644 (.*?)(?= create mode 100644 | Push from your normal checkout)', receipt['text'])
    if len(displayed) != 9:
        raise ValueError('exact nine created paths required')
    for got, expected in zip(displayed, policy['accepted_step346_paths']):
        if got.strip() not in (expected, expected.replace('.', '\\.')):
            raise ValueError('reported created path mismatch')
    return True


def validate_reconciliation(value, history):
    freeze = historical_json(history, 'scoped-candidate-artifact-freeze-gap-register-and-safe-pause-review-freeze')
    gaps = historical_json(history, 'scoped-candidate-artifact-freeze-gap-register-and-safe-pause-review-gap-register')
    plan = historical_json(history, 'offline-transition-core-resume-planning-review-plan')
    expected = {key: freeze[key] for key in FROZEN_FIELDS}
    expected.update({key: gaps[key] for key in GAP_FIELDS})
    exact(value['retained_full_normative_rows'], expected, 'complete original normative rows with no omissions or waiver')
    exact(value['counts'], plan['counts'], 'all original counts')
    exact(value['original_pause_conditions'], plan['pause_conditions'], 'all original pause conditions')
    exact(value['repository_source_conflicts_found'], [], 'unresolved source conflict blocks freeze')
    exact(value['repository_reconciliation_complete'], True, 'repository-only reconciliation complete')
    exact(value['current347_user_acceptance_pending'], True, 'current acceptance remains pending')
    exact(value['actual_host_state'], 'unobserved-not-claimed-absent', 'actual host unobserved')
    exact(value['actual_live_bindings'], None, 'no live binding')
    exact(value['production_entry_closed'], True, 'production closed')
    for key in ('repository_reconciliation_is_native_refinement', 'runtime_authority', 'actual_operational_implementation_frozen', 'operational_conformance', 'operational_readiness', 'phase1_matrix_complete', 'kernel_package_edge_complete', 'phase2_open', 'strong_safe_pause'):
        exact(value[key], False, 'native boundary ' + key)
    for key in ('native_proofs_added', 'native_cases_run'):
        exact(value[key], 0, 'zero native evidence')
    exact(value['last_confirmed_strong_safe_pause_step'], 338, 'last confirmed338')
    registry = value['offline_artifact_registry339_346']
    exact(len(registry), 72, 'all72 accepted offline artifacts')
    policies = {json.loads(raw)['step']: json.loads(raw) for path, raw in history.items() if path.startswith(FIXTURE + PREFIX + 'offline-') and path.endswith('-policy.json')}
    previous = policies[339]['baseline_sha256_bindings']
    expected_paths = []
    for step in range(339, 347):
        after = history if step == 346 else policies[step+1]['baseline_sha256_bindings']
        new = sorted(set(after) - set(previous))
        exact(len(new), 9, 'exact additions per accepted step')
        expected_paths.extend((step, path) for path in new)
        previous = after
    exact([(x['step'], x['path']) for x in registry], expected_paths, 'all source-selected artifact paths')
    for item in registry:
        exact(sha(history[item['path']]), item['sha256'], 'accepted artifact bytes')
    exact([x['step'] for x in value['accepted_checkpoint_chain338_346']], list(range(338, 347)), 'full accepted checkpoint order')
    for row in value['accepted_checkpoint_chain338_346'][:-1]:
        for key in ('confirmation', 'receipt'):
            bound = row[key]
            exact(sha(history[bound['path']]), bound['sha256'], 'historical full acceptance bytes')
        confirmation = json.loads(history[row['confirmation']['path']])
        exact(row['commit_prefix'], confirmation['commit_prefix'], 'reported historical prefix')
        exact(row['acceptance_result'], confirmation['acceptance_result'], 'historical acceptance count')
        exact(row['complete_user_return_accepted'], True, 'complete original receipt accepted')
    return True


def expected_links(phases, retained):
    selected = set(phases)
    proofs = [x for x in retained['qualified_proof_reconciliation'] if selected.intersection(x['candidate_phase_ids'])]
    cases = {(y['platform'], y['case_id']) for x in proofs for y in x['required_native_case_tuples']}
    return {'phase_ids': list(phases),
        'interface_ids': [x['id'] for x in retained['all26_nominal_interfaces'] if any(y['id'] in selected for y in x['allowed_phase_contexts'])],
        'domain_ids': [x['id'] for x in retained['effect_domain_reconciliation'] if selected.intersection(x['phase_ids'])],
        'rights_windows': [x['window'] for x in retained['authority_window_reconciliation'] if selected.intersection(x['phase_ids'])],
        'qualified_proof_ids': [x['qualified_id'] for x in proofs],
        'native_case_tuples': [list(x) for x in sorted(cases)],
        'macro_cut_ids': [x['id'] for x in retained['macro_cut_obligations'] if x['phase_id'] in selected]}


def validate_rule_map(value, reconciliation, history):
    retained = reconciliation['retained_full_normative_rows']
    original = historical_json(history, 'offline-state-event-schema-review-phase-map')
    exact(value['modules'], reconciliation['model_modules'], 'same frozen modules')
    exact(value['source_index_is_native_refinement'], False, 'source index cannot be proof')
    exact(value['no_standalone_phase_windows'], original['no_standalone_phase_windows'], 'service and forbidden windows not invented phases')
    exact([x['original_phase'] for x in value['phase_rows']], retained['all27_phase_boundaries'], 'every original phase in source order')
    expected_family_paths = {'admission': 'admission-launch-reducer', 'bootstrap': 'bootstrap-guard-reducer', 'worker': 'worker-stages-reducer', 'recovery': 'retained-recovery-reducer', 'finalization': 'target-publication-reducer'}
    phases_by_family = {}
    for row in value['phase_rows']:
        phase, family = row['id'], row['family']
        mapping = historical_json(history, 'offline-' + expected_family_paths[family] + '-review-phase-map')
        if phase not in mapping['phase_rows']:
            raise ValueError('wrong reducer family for original phase')
        exact(row['id'], row['original_phase']['id'], 'same original phase')
        exact(row['module'], value['modules'][family], 'same frozen phase module')
        positive = {k: mapping[k][phase] for k in ('required_positive_views', 'budget_positive_views', 'effect_positive_views') if k in mapping and phase in mapping[k]}
        exact(row['positive_view_contracts'], positive, 'complete same positive-view contracts')
        exact(row['original_all_phase_view_types'], original['phase_view_types'][phase], 'all phase type contexts')
        exact(row['inherited_links'], expected_links([phase], retained), 'full qualified phase associations')
        exact(row['native_proof'], False, 'no native phase proof')
        exact(row['actual_native_event_mapping'], None, 'native events unselected')
        phases_by_family.setdefault(family, []).append(phase)
    rows_by_id = {x['id']: x for x in value['rule_rows']}
    exact(len(rows_by_id), len(value['rule_rows']), 'unique rule IDs')
    expected_ids = set()
    for family, bound in value['modules'].items():
        source = history[bound['path']].decode('utf-8')
        exact(sha(history[bound['path']]), bound['sha256'], 'frozen model byte binding')
        tree = ast.parse(source)
        phases = list(original['phases']) if family in ('schema', 'composition') else phases_by_family[family]
        for top in tree.body:
            if not isinstance(top, (ast.FunctionDef, ast.ClassDef)):
                continue
            nodes = [(top, 'definition')] + [(n, 'conditional-guard') for n in ast.walk(top) if isinstance(n, ast.If)]
            for node, kind in nodes:
                ident = family + '/' + top.name + '/' + str(node.lineno) + '/' + kind
                expected_ids.add(ident)
                row = rows_by_id[ident]
                exact(row['module'], bound, 'rule exact frozen source')
                exact(row['family'], family, 'rule family')
                exact(row['owner'], top.name, 'rule owner')
                exact(row['kind'], kind, 'rule kind')
                exact(row['line_start'], node.lineno, 'source start')
                exact(row['line_end'], node.end_lineno, 'source end')
                exact(row['source_span_sha256'], sha(ast.get_source_segment(source, node).encode()), 'full rule span bytes')
                exact(row['condition'], ast.get_source_segment(source, node.test) if kind == 'conditional-guard' else None, 'literal source condition')
                exact(row['inherited_links'], expected_links(phases, retained), 'complete family design associations')
                exact(row['native_proof'], False, 'private rule cannot prove native')
                exact(row['actual_native_event_mapping'], None, 'native rule mapping absent')
        for name, entry in value['declared_family_controls'][family].items():
            matched = [n for n in tree.body if isinstance(n, ast.Assign) and any(isinstance(t, ast.Name) and t.id == name for t in n.targets)]
            exact(len(matched), 1, 'declared control exists once')
            exact(entry, {'line': matched[0].lineno, 'source': ast.get_source_segment(source, matched[0])}, 'closed dispositions and controls unchanged')
    exact(sorted(rows_by_id), sorted(expected_ids), 'every source definition and conditional guard exactly once')
    return True


def validate_gap_register(value, reconciliation, mapping, history):
    original = historical_json(history, 'scoped-candidate-artifact-freeze-gap-register-and-safe-pause-review-gap-register')
    exact(value['native_case_templates'], original['native_case_templates'], 'all52 full native case templates still unrun')
    exact(value['qualified_proofs'], original['qualified_proofs'], 'all46 full qualified proofs still unproven')
    exact(len(value['native_gap_rows']), 16, 'all16 unresolved gaps')
    for row, old in zip(value['native_gap_rows'], original['native_gap_register']):
        exact({k: row[k] for k in old}, old, 'full native gap unweakened')
        exact(row['native_status_promoted'], False, 'gap still unresolved')
    known = {x['inherited_gap']['id'] for x in original['native_gap_register']}
    for row in mapping['phase_rows'] + mapping['rule_rows']:
        if not row['native_gap_ids'] or not set(row['native_gap_ids']) <= known:
            raise ValueError('missing or foreign native gap relation')
        for gap_id in row['native_gap_ids']:
            gap = next(x for x in value['native_gap_rows'] if x['inherited_gap']['id'] == gap_id)
            if row['family'] not in gap['offline_families']:
                raise ValueError('contradictory phase-rule-gap association')
    exact(sorted(x['family'] for x in value['unresolved_event_rows']), sorted(mapping['modules']), 'every model unresolved event family')
    for row in value['unresolved_event_rows']:
        family = row['family']
        exact(row['declared_disposition_reason_source'], mapping['declared_family_controls'][family], 'all declared closed statuses and reasons')
        exact(row['rule_ids'], [x['id'] for x in mapping['rule_rows'] if x['family'] == family], 'full unresolved rule inventory')
        exact(row['private_status_is_actual_evidence'], False, 'private outcome not evidence')
    exact(value['composition_contract'], historical_json(history, 'offline-whole-sequence-audit-review-contract'), 'full unchanged finite346 coverage and clock boundary')
    for key in ('runtime_authority', 'operational_readiness'):
        exact(value[key], False, 'gap register no promotion')
    for key in ('native_cases_run', 'native_proofs_added'):
        exact(value[key], 0, 'no native work')
    return True


def verify(root):
    root = Path(root).absolute()
    if not root.is_dir() or root.resolve() != root:
        raise ValueError('safe repository root required')
    for relative, digest in OWN_HASHES.items():
        exact(sha(safe_file(root, relative).read_bytes()), digest, 'current347 exact artifact')
    load = lambda tail: json.loads(safe_file(root, FIXTURE + BASE + '-' + tail + '.json').read_bytes())
    policy = load('policy')
    history = {}
    for relative, digest in policy['baseline_sha256_bindings'].items():
        raw = safe_file(root, relative).read_bytes()
        if relative == 'CHANGELOG.md':
            size = policy['accepted_changelog_size']
            if len(raw) <= size:
                raise ValueError('missing exact additive347 changelog')
            exact(sha(raw[:-size]), ADDITION_SHA, 'exact347 changelog prefix')
            raw = raw[-size:]
        exact(sha(raw), digest, 'accepted346 bytes ' + relative)
        history[relative] = raw
    exact(len(history), 1701, 'all1701 accepted files')
    validate_return(load('checkpoint-confirmation'), load('step346-user-acceptance'), policy)
    reconciliation, mapping, gaps = load('reconciliation'), load('rule-map'), load('native-gap-register')
    validate_reconciliation(reconciliation, history)
    validate_rule_map(mapping, reconciliation, history)
    validate_gap_register(gaps, reconciliation, mapping, history)
    return history


def main(argv):
    if argv == ['--help']:
        print('Repository-only contract reconciliation: --check REPOSITORY')
        return 0
    if len(argv) != 2 or argv[0] != '--check' or not argv[1]:
        return 2
    try:
        verify(argv[1])
    except (ValueError, KeyError, TypeError, OSError) as error:
        print('ERROR: ' + str(error), file=sys.stderr)
        return 1
    print('step347_offline_contract_reconciliation_status\tPASS')
    print('runtime_authority\tno')
    print('native_cases_run\t0')
    print('native_proofs_added\t0')
    return 0


if __name__ == '__main__':
    raise SystemExit(main(sys.argv[1:]))
