#!/usr/bin/env python3
"""Review inactive independent oracle and full conservative migration impacts proposals from supplied data only."""
import hashlib
import json
import re

POLICY_SHA = 'b9d3901123eb640639e6479fdac9edbc5d8f83eb1c97923cbe8eeac58945f1da'

def sha(raw):
    return hashlib.sha256(raw).hexdigest()

def canonical(value):
    return sha(json.dumps(value, sort_keys=True, separators=(',', ':'), ensure_ascii=True).encode())

def exact(value, expected, label):
    if type(value) is not type(expected) or canonical(value) != canonical(expected):
        raise ValueError(label)
    return True

def validate_policy(policy):
    return exact(canonical(policy), POLICY_SHA, 'authored396 policy substitution')

def validate_inputs(inputs, source_blobs, sources, policy):
    validate_policy(policy)
    exact(canonical(sources), policy['fixture_canonical_sha256']['sources'], 'whole source register')
    exact(sorted(inputs), sorted(sources['inputs']), 'all57 original input keys')
    for key, row in sources['inputs'].items():
        exact(sha(inputs[key]), row['sha256'], 'whole original input bytes ' + key)
        exact(canonical(json.loads(inputs[key])), row['canonical_sha256'], 'whole original JSON ' + key)
    frozen = json.loads(inputs['freeze388'])
    inherited = {key: row['path'] for key, row in sources['inputs'].items() if key in frozen['frozen_inputs']['paths']}
    exact(inherited, frozen['frozen_inputs']['paths'], 'all40 original normative references')
    roots = sources['inert_roots'] + sources['reviewer_roots'] + [sources['readme']]
    exact(sorted(source_blobs), sorted(row['path'] for row in roots), 'four inert seventeen reviewer and README roots')
    for row in roots:
        exact(sha(source_blobs[row['path']]), row['sha256'], 'whole source root ' + row['path'])
    return True

def validate_baseline(blobs, baseline, addition, policy):
    validate_policy(policy)
    exact(canonical(baseline), policy['fixture_canonical_sha256']['baseline'], 'whole accepted395 baseline manifest')
    exact(sorted(blobs), sorted(baseline), 'all2090 original repository paths')
    exact(sha(addition), policy['changelog_addition_sha256'], 'exact additive396 CHANGELOG prefix')
    for path, digest in baseline.items():
        raw = blobs[path]
        if path == 'CHANGELOG.md':
            if not raw.startswith(addition):
                raise ValueError('missing396 CHANGELOG prefix')
            raw = raw[len(addition):]
        exact(sha(raw), digest, 'whole accepted395 bytes ' + path)
    return True

def validate_entry(entry, policy):
    validate_policy(policy)
    exact(canonical(entry), policy['fixture_canonical_sha256']['entry395'], 'whole accepted395 receipt and confirmation')
    raw = entry['receipt']['text'].encode('utf-8')
    exact(sha(raw), policy['predecessor_receipt_sha256'], 'unchanged uploaded395 bytes')
    exact(len(raw), policy['predecessor_receipt_size_bytes'], 'complete395 receipt size')
    text = entry['receipt']['text']
    exact([line for line in text.splitlines() if line.startswith('PASS: ')], policy['required_predecessor_PASS_labels'], 'all426 ordered395 labels')
    exact(re.findall(r'^ create mode 100644 (.+)$', text, re.M), policy['required_predecessor_create_paths'], 'eight exact395 create paths')
    for marker in ['step395_overlay_application_status\tPASS', 'step395_commit_scope_verification_status\tPASS',
                   'Result: PASS (426 passes, 0 failures)', '[main 866e47a] Phase 1 step 395: document whole entry and backend scope options',
                   ' 9 files changed, 22378 insertions(+)', '   d04de75..866e47a  main -> main\n']:
        exact(text.count(marker), 1, 'single395 marker '+marker)
    exact(text.split('   d04de75..866e47a  main -> main\n')[1], policy['expected_predecessor_tail'], 'clean matching reported395 heads')
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
    for name, value in [('entry395', entry), ('baseline', baseline), ('brief', brief), ('sources', sources)]:
        exact(canonical(value), policy['fixture_canonical_sha256'][name], 'whole396 fixture ' + name)
    return True

def validate_brief_shape(brief, inputs, sources, policy):
    """Check inactive proposals, exact originals and conditional policy witnesses."""
    validate_policy(policy)
    plan = json.loads(inputs['plan389'])
    original = json.loads(inputs['accepted385dossier'])
    exact(brief['schema'], 1, 'integer schema')
    exact(brief['step'], 396, 'integer396 step')
    exact(brief['primary_conflict_ids'], ['independent-two-platform-native-oracle'], 'whole original independent oracle conflict')
    exact(brief['whole_original_oracle_review'], original, 'WHOLE unchanged385 independent graph oracle review')
    for key, section, field in [('original326', 'independent_conformance_contract', 'original326_independent_conformance_contract'), ('original326', 'model_contract', 'original326_model_contract'), ('independent_scaffold335', 'independence_contract', 'original335_independence_contract')]:
        exact(json.loads(inputs[key])[section], original[field], 'WHOLE actual original oracle clause '+key+section)
    exact(json.loads(inputs['independent_expectation351']), original['original351_whole_expectation_contract'], 'WHOLE original351 expectations remain private/native unknown')
    for field, key in policy['whole_reference_fields'].items():
        exact(brief[field], sources['inputs'][key], 'whole reference '+key)
    for key in policy['prior_option_input_keys']:
        prior = json.loads(inputs[key])
        exact(prior['selected_option'], None, 'prior proposal still unselected')
        exact(prior['approved_contract_migration'], None, 'prior migration still inactive')
    exact(brief['boundaries'], plan['boundaries'], 'every original closed boundary')
    for key in ['selected_option', 'approved_contract_migration', 'actual_expectation_author', 'actual_collector', 'actual_verifier', 'actual_fault_injector', 'actual_native_expected_vectors', 'actual_platform_run_evidence']:
        exact(brief[key], None, 'inactive or unknown '+key)
    for key in ['native_authority', 'source_documentation_is_native_proof', 'universal_impossibility_proven', 'current_step_strong_safe_pause', 'semantic_migration_complete', 'independent_impact_review_accepted', 'integrated_selection_review_complete']:
        exact(brief[key], False, 'no promotion '+key)
    for key in ['new_native_proofs', 'new_native_cases']:
        exact(brief[key], 0, 'no native progress')
    exact(brief['impact_coverage_complete'], True, 'full conservative coverage authored only')
    exact(brief['whole_original_requirements_remain_normative'], True, 'full original contracts remain binding')
    exact(brief['conditional_close_step'], 398, 'finite close398')
    exact(brief['next_preparable_step_after_complete396_acceptance'], 397, 'actual396 acceptance before397')
    options = brief['options']
    exact([o['id'] for o in options], policy['expected_option_ids'], 'three explicit original oracle alternatives')
    exact([o['disposition'] for o in options], policy['expected_dispositions'], 'retention independent raw-oracle hypothesis and deferral')
    ids = [r['id'] for r in plan['whole_original_conflicts']]
    for opt in options:
        exact(sorted(opt), sorted(plan['proposal_rules']['required_option_fields']), 'complete option fields')
        exact([[r['input_key'], r['json_pointer']] for r in opt['exact_current_clause_bindings']], policy['expected_clause_pairs'], 'all nine whole oracle clause bindings')
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

def member_ids(category_id, whole):
    if type(whole) is dict:
        return list(whole)
    if category_id == 'ordered-proof-case-relations':
        return [r['qualified_proof_id']+'@'+r['platform']+'@'+r['case_id'] for r in whole]
    if category_id == 'native-cases347':
        return [r['platform']+'@'+r['case_id'] for r in whole]
    return [r.get('qualified_id', r.get('id', r.get('family', r.get('gap_id', str(i))))) for i, r in enumerate(whole)]

def validate_impacts(brief, inputs, sources, policy):
    """Enumerate every original member conservatively; never approve replacements."""
    validate_policy(policy)
    categories = brief['impact_categories']
    exact([[c['id'], c['input_key'], c['json_pointer']] for c in categories], policy['expected_category_specs'], 'all fifteen full categories in original order')
    decoded = {key: json.loads(raw) for key, raw in inputs.items()}
    for cat in categories:
        whole = pointer(decoded[cat['input_key']], cat['json_pointer'])
        exact(cat['path'], sources['inputs'][cat['input_key']]['path'], 'actual original category path')
        exact(cat['whole_current_value'], whole, 'WHOLE original category '+cat['id'])
        exact(cat['whole_current_value_canonical_sha256'], canonical(whole), 'whole category canonical binding')
        exact(cat['ordered_member_ids'], member_ids(cat['id'], whole), 'every original member and ordered multiplicity')
        exact(len(cat['ordered_member_ids']), policy['expected_category_counts'][cat['id']], 'exact full category count')
    historical = next(c for c in categories if c['id']=='historical-five-families')
    exact(sum(r['scenarios'] for r in historical['whole_current_value']), 20, 'five historical families/twenty scenarios remain separate')
    option_rows = [(key, index, opt) for key in policy['prior_option_input_keys'] for index, opt in enumerate(decoded[key]['options'])]
    option_rows += [('current396', index, opt) for index, opt in enumerate(brief['options'])]
    reviews = brief['all_option_impact_reviews']
    exact([r['option_id'] for r in reviews], policy['expected_all_impact_option_ids'], 'all twenty-six option impact rows')
    for row, (key, index, opt) in zip(reviews, option_rows):
        exact(row['source_input_key'], key, 'exact proposal source')
        exact(row['source_option_index'], index, 'exact source option index')
        exact(row['whole_option_canonical_sha256'], canonical(opt), 'whole unchanged option')
        exact(row['disposition'], opt['disposition'], 'unchanged option disposition')
        exact(row['whole_current_clause_bindings_canonical_sha256'], canonical(opt['exact_current_clause_bindings']), 'whole original option clause basis')
        exact(row['guarantees_lost_or_changed'], opt['guarantees_lost_or_changed'], 'whole unchanged guarantee losses')
        exact(row['proposed_clause_text'], opt['proposed_clause_text'], 'whole exact inactive proposed wording')
        changes = [{**c, 'path': sources['inputs'][c['input_key']]['path'], 'whole_current_value': pointer(decoded[c['input_key']], c['json_pointer']), 'replacement_semantically_reconciled': False, 'approved_replacement': None} for c in opt['migration_impact']['exact_changed_clause_candidates']]
        exact(row['exact_changed_clause_review'], changes, 'all exact changed clauses retained unresolved')
        expected = [{'category_id': c['id'], 'whole_current_value_canonical_sha256': c['whole_current_value_canonical_sha256'], 'ordered_member_ids': c['ordered_member_ids'], 'review_disposition': 'potential-downstream-amendment-impact-requalification-required' if opt['disposition']=='amendment-proposal' else 'whole-current-obligations-retained-native-integration-unproven', 'all_current_requirements_retained': True, 'semantic_migration_reconciled': False, 'replacement_obligations': None, 'actual_native_evidence': None} for c in categories]
        exact(row['category_reviews'], expected, 'all full downstream members covered without pruning or resolution')
        exact(row['coverage_complete'], True, 'authored complete coverage only')
        for field in ['semantic_migration_complete', 'native_conformance_proven', 'selected', 'runtime_authority']:
            exact(row[field], False, 'no impact promotion '+field)
        exact(row['approved_migration'], None, 'no approved impact migration')
    return True

def review(entry, baseline, brief, sources, inputs, source_blobs, policy):
    validate_fixtures(entry, baseline, brief, sources, policy)
    validate_inputs(inputs, source_blobs, sources, policy)
    validate_entry(entry, policy)
    validate_brief_shape(brief, inputs, sources, policy)
    validate_impacts(brief, inputs, sources, policy)
    return json.loads(json.dumps({
        'step': 396, 'state': 'prepared-inactive-oracle-impact-brief-user-acceptance-pending',
        'brief': brief, 'whole_entry395': entry, 'whole_input_bindings': sources['inputs'],
        'last_confirmed_repository_pause': 388, 'strong_safe_pause': False,
        'impact_coverage_complete': True, 'semantic_migration_complete': False,
        'selected_option': None, 'approved_contract_migration': None, 'native_authority': False,
        'conditional_close_step': 398, 'after_actual396_acceptance_next_preparable_step': 397,
        'next_authorized_stage_after398': None,
    }))
