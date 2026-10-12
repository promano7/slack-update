#!/usr/bin/env python3
"""Review inactive writer/trust proposals from supplied data only."""
import hashlib
import json
import re

POLICY_SHA = '26ec948117e5e9fda0f1e2204976fb561eaafc3808ef801c9fada801954d4035'

def sha(raw):
    return hashlib.sha256(raw).hexdigest()

def canonical(value):
    return sha(json.dumps(value, sort_keys=True, separators=(',', ':'), ensure_ascii=True).encode())

def exact(value, expected, label):
    if type(value) is not type(expected) or canonical(value) != canonical(expected):
        raise ValueError(label)
    return True

def validate_policy(policy):
    return exact(canonical(policy), POLICY_SHA, 'authored390 policy substitution')

def validate_inputs(inputs, source_blobs, sources, policy):
    validate_policy(policy)
    exact(canonical(sources), policy['fixture_canonical_sha256']['sources'], 'whole source register')
    exact(sorted(inputs), sorted(sources['inputs']), 'all44 original input keys')
    for key, row in sources['inputs'].items():
        exact(sha(inputs[key]), row['sha256'], 'whole original input bytes ' + key)
        exact(canonical(json.loads(inputs[key])), row['canonical_sha256'], 'whole original JSON ' + key)
    frozen = json.loads(inputs['freeze388'])
    inherited = {key: row['path'] for key, row in sources['inputs'].items() if key not in ['freeze388', 'pause388', 'plan389', 'original324']}
    exact(inherited, frozen['frozen_inputs']['paths'], 'all40 original normative references')
    roots = sources['inert_roots'] + sources['reviewer_roots'] + [sources['readme']]
    exact(sorted(source_blobs), sorted(row['path'] for row in roots), 'four inert eleven reviewer and README roots')
    for row in roots:
        exact(sha(source_blobs[row['path']]), row['sha256'], 'whole source root ' + row['path'])
    return True

def validate_baseline(blobs, baseline, addition, policy):
    validate_policy(policy)
    exact(canonical(baseline), policy['fixture_canonical_sha256']['baseline'], 'whole accepted389 baseline manifest')
    exact(sorted(blobs), sorted(baseline), 'all2042 original repository paths')
    exact(sha(addition), policy['changelog_addition_sha256'], 'exact additive390 CHANGELOG prefix')
    for path, digest in baseline.items():
        raw = blobs[path]
        if path == 'CHANGELOG.md':
            if not raw.startswith(addition):
                raise ValueError('missing390 CHANGELOG prefix')
            raw = raw[len(addition):]
        exact(sha(raw), digest, 'whole accepted389 bytes ' + path)
    return True

def validate_fixtures(entry, baseline, brief, sources, policy):
    validate_policy(policy)
    for name, value in [('entry389', entry), ('baseline', baseline), ('brief', brief), ('sources', sources)]:
        exact(canonical(value), policy['fixture_canonical_sha256'][name], 'whole390 fixture ' + name)
    return True


def validate_entry(entry, policy):
    validate_policy(policy)
    exact(canonical(entry), policy['fixture_canonical_sha256']['entry389'], 'whole accepted389 receipt and confirmation')
    raw = entry['receipt']['text'].encode('utf-8')
    exact(sha(raw), policy['predecessor_receipt_sha256'], 'unchanged uploaded389 bytes')
    exact(len(raw), policy['predecessor_receipt_size_bytes'], 'complete389 receipt size')
    text = entry['receipt']['text']
    exact([line for line in text.splitlines() if line.startswith('PASS: ')], policy['required_predecessor_PASS_labels'], 'all171 ordered389 labels')
    exact(re.findall(r'^ create mode 100644 (.+)$', text, re.M), policy['required_predecessor_create_paths'], 'eight exact389 create paths')
    for marker in ['step389_overlay_application_status\tPASS', 'step389_commit_scope_verification_status\tPASS',
                   'Result: PASS (171 passes, 0 failures)', '[main 85db946] Phase 1 step 389: plan bounded contract decision proposals',
                   ' 9 files changed, 4563 insertions(+)', '   d31ba23..85db946  main -> main\n']:
        exact(text.count(marker), 1, 'single389 marker ' + marker)
    exact(text.split('   d31ba23..85db946  main -> main\n')[1], policy['expected_predecessor_tail'], 'clean matching reported389 heads')
    return True


def pointer(value, path):
    for key in path.lstrip('/').split('/'):
        value = value[key.replace('~1', '/').replace('~0', '~')]
    return value


def validate_brief_shape(brief, inputs, sources):
    """Enforce inactive option and complete-clause boundaries independent of digest."""
    plan = json.loads(inputs['plan389'])
    writer = json.loads(inputs['accepted381dossier'])
    original = json.loads(inputs['original324'])
    exact(brief['schema'], 1, 'integer schema')
    exact(brief['step'], 390, 'integer390 step')
    exact(brief['primary_conflict_id'], 'all-writer-privileged-alias-lifetime', 'original writer conflict')
    exact(brief['whole_original_writer_review'], writer, 'whole unchanged381 review')
    exact(original['guard_contract'], writer['original324_guard_contract'], 'actual original324 guard clauses')
    exact(brief['whole_original_324_guard_design_reference'], sources['inputs']['original324'], 'whole original324 reference')
    exact(brief['whole_plan389_reference'], sources['inputs']['plan389'], 'whole finite389 plan reference')
    exact(brief['resource_domain_rows'], writer['original_writer_resource_rows'], 'seven whole original resource rows')
    exact(brief['writer_classes'], writer['trust_boundary_review']['required_writer_classes'], 'all twelve original writer classes')
    exact(brief['writer_classification_is_actual_inventory'], False, 'classification not actual inventory')
    exact(brief['boundaries'], plan['boundaries'], 'every closed native project and host boundary')
    for key in ['actual_writer_inventory', 'actual_trust_boundary', 'actual_guard_policy', 'selected_option', 'approved_contract_migration']:
        exact(brief[key], None, 'unknown or inactive ' + key)
    for key in ['native_authority', 'source_documentation_is_native_proof', 'universal_impossibility_proven', 'current_step_strong_safe_pause']:
        exact(brief[key], False, 'no promotion ' + key)
    for key in ['new_native_proofs', 'new_native_cases']:
        exact(brief[key], 0, 'no native progress claimed')
    exact(brief['whole_original_requirements_remain_normative'], True, 'current full contracts normative')
    exact(brief['conditional_close_step'], 398, 'conditional finite close398')
    exact(brief['next_preparable_step_after_complete390_acceptance'], 391, 'actual390 acceptance before391')
    options = brief['options']
    exact([opt['id'] for opt in options], ['retain-full-original-coverage', 'explicit-trusted-host-boundary', 'defer-native-writer-selection'], 'three ordered explicit alternatives')
    exact([opt['disposition'] for opt in options], plan['proposal_rules']['allowed_dispositions'], 'retention amendment deferral all required')
    expected_bindings = [('original324', '/' + key) for key in ['guard_contract', 'baseline_contract', 'interstage_contract', 'resource_domains']]
    expected_bindings += [('accepted381dossier', '/original377_writer_conflict')]
    ids = [row['id'] for row in plan['whole_original_conflicts']]
    for opt in options:
        exact(sorted(opt), sorted(plan['proposal_rules']['required_option_fields']), 'complete option decision fields')
        exact([(row['input_key'], row['json_pointer']) for row in opt['exact_current_clause_bindings']], expected_bindings, 'complete original clause bindings')
        for row in opt['exact_current_clause_bindings']:
            exact(row['path'], sources['inputs'][row['input_key']]['path'], 'original binding path')
            exact(row['whole_current_value'], pointer(json.loads(inputs[row['input_key']]), row['json_pointer']), 'WHOLE exact current clause object')
        for key in ['guarantees_retained', 'trust_assumptions', 'effect_and_failure_boundaries', 'residual_native_unknowns', 'independent_evidence_required']:
            if type(opt[key]) is not list or not opt[key] or not all(type(s) is str and s.strip() for s in opt[key]):
                raise ValueError('missing substantive option field ' + key)
        exact(opt['dependencies_and_incompatibilities'], ids, 'all eight conflict dependencies retained')
        exact(opt['explicit_user_decision_required'], True, 'separate explicit decision needed')
        exact(opt['implementation_selected'], False, 'no implementation selection')
        exact(opt['runtime_authority'], False, 'no option grants runtime')
        exact([row['platform'] for row in opt['platform_rows']], plan['proposal_rules']['platforms'], 'separate two-platform rows')
        for row in opt['platform_rows']:
            for key in ['installed_versions', 'support', 'actual_composition', 'native_evidence']:
                exact(row[key], None, 'unknown actual platform ' + key)
            exact(row['entry_authorized'], False, 'no native platform entry')
        impact = opt['migration_impact']
        exact(impact['state'], 'initial-draft-incomplete-until396-and397', 'initial impact not final migration')
        exact(impact['whole_guard_and_original_conflict_bindings_retained'], True, 'whole original migration basis')
        exact(impact['all_other_original_clauses_remain_binding'], True, 'other conflicts never waived')
        exact(impact['affected_proofs_cases_relations_complete'], False, 'full impact not yet mapped')
        exact(impact['approved_migration'], None, 'migration unapproved')
        if opt['disposition'] == 'amendment-proposal':
            exact(sorted(opt['proposed_clause_text']), ['/guard_contract/admission', '/guard_contract/coverage', 'trusted_host_assumption'], 'exact proposed change surfaces')
            if not opt['guarantees_lost_or_changed'] or not impact['exact_changed_clause_candidates']:
                raise ValueError('amendment must disclose guarantee loss and original impacts')
            if not all(type(v) is str and v.strip() for v in opt['proposed_clause_text'].values()):
                raise ValueError('missing concrete proposed clause wording')
        else:
            exact(opt['proposed_clause_text'], {}, 'retention and deferral cannot hide amendments')
            exact(opt['guarantees_lost_or_changed'], [], 'retention and deferral preserve current contract')
            exact(impact['exact_changed_clause_candidates'], [], 'retention and deferral no changed clauses')
    return True


def review(entry, baseline, brief, sources, inputs, source_blobs, policy):
    validate_fixtures(entry, baseline, brief, sources, policy)
    validate_inputs(inputs, source_blobs, sources, policy)
    validate_entry(entry, policy)
    validate_brief_shape(brief, inputs, sources)
    return json.loads(json.dumps({
        'step': 390, 'state': 'prepared-inactive-decision-brief-user-acceptance-pending',
        'brief': brief, 'whole_entry389': entry, 'whole_input_bindings': sources['inputs'],
        'last_confirmed_repository_pause': 388, 'strong_safe_pause': False,
        'selected_option': None, 'approved_contract_migration': None, 'native_authority': False,
        'conditional_close_step': 398, 'after_actual390_acceptance_next_preparable_step': 391,
        'next_authorized_stage_after398': None,
    }))
