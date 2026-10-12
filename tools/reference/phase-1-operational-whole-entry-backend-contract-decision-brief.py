#!/usr/bin/env python3
"""Review inactive whole-entry source/backend scope proposals from supplied data only."""
import hashlib
import json
import re

POLICY_SHA = '6b60788d448de61153804ba06f9a1afee68bfa3e9db9ada9caaa9a2010477ef6'

def sha(raw):
    return hashlib.sha256(raw).hexdigest()

def canonical(value):
    return sha(json.dumps(value, sort_keys=True, separators=(',', ':'), ensure_ascii=True).encode())

def exact(value, expected, label):
    if type(value) is not type(expected) or canonical(value) != canonical(expected):
        raise ValueError(label)
    return True

def validate_policy(policy):
    return exact(canonical(policy), POLICY_SHA, 'authored395 policy substitution')

def validate_inputs(inputs, source_blobs, sources, policy):
    validate_policy(policy)
    exact(canonical(sources), policy['fixture_canonical_sha256']['sources'], 'whole source register')
    exact(sorted(inputs), sorted(sources['inputs']), 'all56 original input keys')
    for key, row in sources['inputs'].items():
        exact(sha(inputs[key]), row['sha256'], 'whole original input bytes ' + key)
        exact(canonical(json.loads(inputs[key])), row['canonical_sha256'], 'whole original JSON ' + key)
    frozen = json.loads(inputs['freeze388'])
    inherited = {key: row['path'] for key, row in sources['inputs'].items() if key in frozen['frozen_inputs']['paths']}
    exact(inherited, frozen['frozen_inputs']['paths'], 'all40 original normative references')
    roots = sources['inert_roots'] + sources['reviewer_roots'] + [sources['readme']]
    exact(sorted(source_blobs), sorted(row['path'] for row in roots), 'four inert sixteen reviewer and README roots')
    for row in roots:
        exact(sha(source_blobs[row['path']]), row['sha256'], 'whole source root ' + row['path'])
    return True

def validate_baseline(blobs, baseline, addition, policy):
    validate_policy(policy)
    exact(canonical(baseline), policy['fixture_canonical_sha256']['baseline'], 'whole accepted394 baseline manifest')
    exact(sorted(blobs), sorted(baseline), 'all2082 original repository paths')
    exact(sha(addition), policy['changelog_addition_sha256'], 'exact additive395 CHANGELOG prefix')
    for path, digest in baseline.items():
        raw = blobs[path]
        if path == 'CHANGELOG.md':
            if not raw.startswith(addition):
                raise ValueError('missing395 CHANGELOG prefix')
            raw = raw[len(addition):]
        exact(sha(raw), digest, 'whole accepted394 bytes ' + path)
    return True

def validate_entry(entry, policy):
    validate_policy(policy)
    exact(canonical(entry), policy['fixture_canonical_sha256']['entry394'], 'whole accepted394 receipt and confirmation')
    raw = entry['receipt']['text'].encode('utf-8')
    exact(sha(raw), policy['predecessor_receipt_sha256'], 'unchanged uploaded394 bytes')
    exact(len(raw), policy['predecessor_receipt_size_bytes'], 'complete394 receipt size')
    text = entry['receipt']['text']
    exact([line for line in text.splitlines() if line.startswith('PASS: ')], policy['required_predecessor_PASS_labels'], 'all409 ordered394 labels')
    exact(re.findall(r'^ create mode 100644 (.+)$', text, re.M), policy['required_predecessor_create_paths'], 'eight exact394 create paths')
    for marker in ['step394_overlay_application_status\tPASS', 'step394_commit_scope_verification_status\tPASS',
                   'Result: PASS (409 passes, 0 failures)', '[main d04de75] Phase 1 step 394: document stage12 and terminal receipt options',
                   ' 9 files changed, 6675 insertions(+)', '   17db6be..d04de75  main -> main\n']:
        exact(text.count(marker), 1, 'single394 marker '+marker)
    exact(text.split('   17db6be..d04de75  main -> main\n')[1], policy['expected_predecessor_tail'], 'clean matching reported394 heads')
    return True

def pointer(value, path):
    for encoded in path.lstrip('/').split('/'):
        key = encoded.replace('~1', '/').replace('~0', '~')
        if type(value) is list:
            if not re.fullmatch(r'0|[1-9][0-9]*', key) or int(key) >= len(value):
                raise ValueError('invalid list pointer')
            value = value[int(key)]
        else:
            value = value[key]
    return value

def validate_fixtures(entry, baseline, brief, sources, policy):
    validate_policy(policy)
    for name, value in [('entry394', entry), ('baseline', baseline), ('brief', brief), ('sources', sources)]:
        exact(canonical(value), policy['fixture_canonical_sha256'][name], 'whole395 fixture ' + name)
    return True

def validate_brief_shape(brief, inputs, sources, policy):
    """Check inactive proposals, exact originals and conditional policy witnesses."""
    validate_policy(policy)
    plan = json.loads(inputs['plan389'])
    original = json.loads(inputs['accepted385dossier'])
    exact(brief['schema'], 1, 'integer schema')
    exact(brief['step'], 395, 'integer395 step')
    exact(brief['primary_conflict_ids'], ['whole-entry-and-real-backend'], 'whole original entry backend conflict')
    exact(brief['whole_original_entry_backend_review'], original, 'WHOLE unchanged385 graph oracle review')
    for key, section, field in [('original325', 'graph_contract', 'original325_graph_contract'), ('original325', 'selector_contract', 'original325_selector_contract'), ('original325', 'nested_argv_contract', 'original325_nested_argv_contract'), ('original325', 'reference_census', 'original325_reference_census'), ('original325', 'reference_review_binding', 'original325_reference_review_binding'), ('original325', 'catalogue_nodes', 'original325_catalogue_nodes'), ('original325', 'catalogue_edges', 'original325_catalogue_edges'), ('original321', 'authentication', 'original321_authentication'), ('original321', 'bootstrap', 'original321_bootstrap'), ('original321', 'fd_policy', 'original321_fd_policy'), ('original326', 'model_contract', 'original326_model_contract'), ('original326', 'independent_conformance_contract', 'original326_independent_conformance_contract')]:
        exact(json.loads(inputs[key])[section], original[field], 'WHOLE actual original clause '+key+section)
    for field, key in policy['whole_reference_fields'].items():
        exact(brief[field], sources['inputs'][key], 'whole reference '+key)
    for key in ['writer_brief390', 'revocation_brief391', 'loss_brief392', 'storage_brief393', 'receipt_brief394']:
        prior = json.loads(inputs[key])
        exact(prior['selected_option'], None, 'prior proposal still unselected')
        exact(prior['approved_contract_migration'], None, 'prior migration still inactive')
    exact(brief['boundaries'], plan['boundaries'], 'every original closed boundary')
    for key in ['selected_option', 'approved_contract_migration', 'actual_selected_entry', 'actual_source_consumption_graph', 'actual_backend', 'actual_selector', 'actual_hook_effects', 'actual_raw_ordered_vectors']:
        exact(brief[key], None, 'inactive or unknown '+key)
    for key in ['native_authority', 'source_documentation_is_native_proof', 'universal_impossibility_proven', 'current_step_strong_safe_pause']:
        exact(brief[key], False, 'no promotion '+key)
    for key in ['new_native_proofs', 'new_native_cases']:
        exact(brief[key], 0, 'no native progress')
    exact(brief['whole_original_requirements_remain_normative'], True, 'full original contracts remain binding')
    exact(brief['conditional_close_step'], 398, 'finite close398')
    exact(brief['next_preparable_step_after_complete395_acceptance'], 396, 'actual395 acceptance before396')
    questions = brief['conditional_graph_questions']
    exact([r['id'] for r in questions], policy['expected_graph_surface_ids'], 'eight whole original graph surface questions')
    original_rows = {r['id']: r for r in original['graph_surface_review']}
    for row in questions:
        exact(row['option_id'], 'complete-protected-source-consumption-hypothesis', 'retention graph hypothesis context')
        exact(row['whole_original_surface'], original_rows[row['id']], 'WHOLE original graph surface retained')
        exact(row['all_original_gates_required'], True, 'all whole original graph gates required')
        for key in ['is_executable_graph', 'limits_whole_original_scope', 'current_authority']:
            exact(row[key], False, 'no question dispatch or scope reduction '+key)
        for key in ['actual_graph_binding', 'actual_independent_evidence']:
            exact(row[key], None, 'no actual question evidence '+key)
    product = brief['separate_product_scope_proposal']
    exact(product['option_id'], 'explicit-separate-backend-product-scope', 'amendment-only product scope')
    for key in ['replaces_whole_entry_claim', 'current_original_test_entry_policy_retained']:
        exact(product[key], True, 'scope change and original test policy retained '+key)
    for key in ['current_original_entry_equivalent', 'phase1_completion_allowed', 'native_test_entry_exception', 'runtime_authority']:
        exact(product[key], False, 'no product promotion '+key)
    for key in ['selected_component', 'selected_entry_interface', 'approved_scope_migration', 'actual_native_component_graph']:
        exact(product[key], None, 'no selected product '+key)
    options = brief['options']
    exact([o['id'] for o in options], policy['expected_option_ids'], 'four explicit original alternatives')
    exact([o['disposition'] for o in options], policy['expected_dispositions'], 'retention protected-graph hypothesis scope amendment and deferral')
    ids = [r['id'] for r in plan['whole_original_conflicts']]
    for opt in options:
        exact(sorted(opt), sorted(plan['proposal_rules']['required_option_fields']), 'complete option fields')
        exact([[r['input_key'], r['json_pointer']] for r in opt['exact_current_clause_bindings']], policy['expected_clause_pairs'], 'all sixteen whole current clause bindings')
        for row in opt['exact_current_clause_bindings']:
            exact(row['path'], sources['inputs'][row['input_key']]['path'], 'bound original path')
            exact(row['whole_current_value'], pointer(json.loads(inputs[row['input_key']]), row['json_pointer']), 'WHOLE current clause')
        for key in ['guarantees_retained', 'trust_assumptions', 'effect_and_failure_boundaries', 'residual_native_unknowns', 'independent_evidence_required']:
            if type(opt[key]) is not list or not opt[key] or not all(type(x) is str and x.strip() for x in opt[key]):
                raise ValueError('missing concrete field ' + key)
        exact(opt['dependencies_and_incompatibilities'], ids, 'all eight conflict dependencies')
        exact(opt['explicit_user_decision_required'], True, 'separate explicit decision')
        exact(opt['implementation_selected'], False, 'no implementation selected')
        exact(opt['runtime_authority'], False, 'no runtime grant')
        exact([r['platform'] for r in opt['platform_rows']], plan['proposal_rules']['platforms'], 'separate actual platform scopes')
        for row in opt['platform_rows']:
            for key in ['installed_versions', 'support', 'actual_composition', 'native_evidence']:
                exact(row[key], None, 'unknown actual platform ' + key)
            exact(row['entry_authorized'], False, 'no actual platform entry')
        impact = opt['migration_impact']
        exact(impact['state'], 'initial-draft-incomplete-until396-and397', 'initial migration not complete')
        exact(impact['whole_current_clause_bindings_retained'], True, 'whole original migration basis')
        exact(impact['all_other_original_clauses_remain_binding'], True, 'other obligations unchanged')
        exact(impact['affected_proofs_cases_relations_complete'], False, 'full impact still pending')
        exact(impact['approved_migration'], None, 'migration inactive')
        exact(sorted(opt['proposed_clause_text']), policy['expected_proposed_clause_keys'][opt['id']], 'exact amendment surfaces')
        if opt['disposition'] == 'amendment-proposal':
            if not opt['guarantees_lost_or_changed'] or not impact['exact_changed_clause_candidates']:
                raise ValueError('hidden amendment guarantee loss or impacts')
            if not all(type(v) is str and v.strip() for v in opt['proposed_clause_text'].values()):
                raise ValueError('missing proposed clause wording')
        else:
            exact(opt['guarantees_lost_or_changed'], [], 'retention and deferral no guarantee change')
            exact(impact['exact_changed_clause_candidates'], [], 'retention and deferral no amendment')
    witnesses = brief['conditional_policy_witnesses']
    exact([r['id'] for r in witnesses], policy['expected_witness_ids'], 'all nine conditional policy witnesses')
    for row in witnesses:
        if row['option_id'] not in policy['expected_option_ids'] or type(row['ordered_events']) is not list or len(row['ordered_events']) < 2:
            raise ValueError('unbound or truncated witness')
        exact(row['actual_observation'], None, 'paper witness not native observation')
        exact(row['native_execution'], False, 'no native witness run')
        exact(row['exhaustive_coverage'], False, 'no exhaustive fault coverage')
    return True

def review(entry, baseline, brief, sources, inputs, source_blobs, policy):
    validate_fixtures(entry, baseline, brief, sources, policy)
    validate_inputs(inputs, source_blobs, sources, policy)
    validate_entry(entry, policy)
    validate_brief_shape(brief, inputs, sources, policy)
    return json.loads(json.dumps({
        'step': 395, 'state': 'prepared-inactive-whole-entry-backend-brief-user-acceptance-pending',
        'brief': brief, 'whole_entry394': entry, 'whole_input_bindings': sources['inputs'],
        'last_confirmed_repository_pause': 388, 'strong_safe_pause': False,
        'selected_option': None, 'approved_contract_migration': None, 'native_authority': False,
        'conditional_close_step': 398, 'after_actual395_acceptance_next_preparable_step': 396,
        'next_authorized_stage_after398': None,
    }))
