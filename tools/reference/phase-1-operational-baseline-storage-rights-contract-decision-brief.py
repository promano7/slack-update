#!/usr/bin/env python3
"""Review inactive capture/storage/rights hypotheses from supplied data only."""
import hashlib
import json
import re

POLICY_SHA = '7aed52b61b96cfe17cf0f462eb20656a873e86acf35b00cd4aad44bf226043b7'

def sha(raw):
    return hashlib.sha256(raw).hexdigest()

def canonical(value):
    return sha(json.dumps(value, sort_keys=True, separators=(',', ':'), ensure_ascii=True).encode())

def exact(value, expected, label):
    if type(value) is not type(expected) or canonical(value) != canonical(expected):
        raise ValueError(label)
    return True

def validate_policy(policy):
    return exact(canonical(policy), POLICY_SHA, 'authored393 policy substitution')

def validate_inputs(inputs, source_blobs, sources, policy):
    validate_policy(policy)
    exact(canonical(sources), policy['fixture_canonical_sha256']['sources'], 'whole source register')
    exact(sorted(inputs), sorted(sources['inputs']), 'all52 original input keys')
    for key, row in sources['inputs'].items():
        exact(sha(inputs[key]), row['sha256'], 'whole original input bytes ' + key)
        exact(canonical(json.loads(inputs[key])), row['canonical_sha256'], 'whole original JSON ' + key)
    frozen = json.loads(inputs['freeze388'])
    inherited = {key: row['path'] for key, row in sources['inputs'].items() if key not in ['freeze388', 'pause388', 'plan389', 'original324', 'writer_brief390', 'original323', 'original321', 'revocation_brief391', 'original326', 'loss_brief392', 'original320', 'original322']}
    exact(inherited, frozen['frozen_inputs']['paths'], 'all40 original normative references')
    roots = sources['inert_roots'] + sources['reviewer_roots'] + [sources['readme']]
    exact(sorted(source_blobs), sorted(row['path'] for row in roots), 'four inert fourteen reviewer and README roots')
    for row in roots:
        exact(sha(source_blobs[row['path']]), row['sha256'], 'whole source root ' + row['path'])
    return True

def validate_baseline(blobs, baseline, addition, policy):
    validate_policy(policy)
    exact(canonical(baseline), policy['fixture_canonical_sha256']['baseline'], 'whole accepted392 baseline manifest')
    exact(sorted(blobs), sorted(baseline), 'all2066 original repository paths')
    exact(sha(addition), policy['changelog_addition_sha256'], 'exact additive393 CHANGELOG prefix')
    for path, digest in baseline.items():
        raw = blobs[path]
        if path == 'CHANGELOG.md':
            if not raw.startswith(addition):
                raise ValueError('missing393 CHANGELOG prefix')
            raw = raw[len(addition):]
        exact(sha(raw), digest, 'whole accepted392 bytes ' + path)
    return True

def validate_entry(entry, policy):
    validate_policy(policy)
    exact(canonical(entry), policy['fixture_canonical_sha256']['entry392'], 'whole accepted392 receipt and confirmation')
    raw = entry['receipt']['text'].encode('utf-8')
    exact(sha(raw), policy['predecessor_receipt_sha256'], 'unchanged uploaded392 bytes')
    exact(len(raw), policy['predecessor_receipt_size_bytes'], 'complete392 receipt size')
    text = entry['receipt']['text']
    exact([line for line in text.splitlines() if line.startswith('PASS: ')], policy['required_predecessor_PASS_labels'], 'all304 ordered392 labels')
    exact(re.findall(r'^ create mode 100644 (.+)$', text, re.M), policy['required_predecessor_create_paths'], 'eight exact392 create paths')
    for marker in ['step392_overlay_application_status\tPASS', 'step392_commit_scope_verification_status\tPASS',
                   'Result: PASS (304 passes, 0 failures)', '[main 63c8c5c] Phase 1 step 392: document owner loss drain and clock trust options',
                   ' 9 files changed, 5233 insertions(+)', '   7f642f3..63c8c5c  main -> main\n']:
        exact(text.count(marker), 1, 'single392 marker ' + marker)
    exact(text.split('   7f642f3..63c8c5c  main -> main\n')[1], policy['expected_predecessor_tail'], 'clean matching reported392 heads')
    return True

def pointer(value, path):
    for key in path.lstrip('/').split('/'):
        value = value[key.replace('~1', '/').replace('~0', '~')]
    return value

def validate_fixtures(entry, baseline, brief, sources, policy):
    validate_policy(policy)
    for name, value in [('entry392', entry), ('baseline', baseline), ('brief', brief), ('sources', sources)]:
        exact(canonical(value), policy['fixture_canonical_sha256'][name], 'whole393 fixture ' + name)
    return True

def validate_brief_shape(brief, inputs, sources, policy):
    """Check inactive proposals, exact originals and conditional policy witnesses."""
    validate_policy(policy)
    plan = json.loads(inputs['plan389'])
    storage = json.loads(inputs['accepted383dossier'])
    exact(brief['schema'], 1, 'integer schema')
    exact(brief['step'], 393, 'integer393 step')
    exact(brief['primary_conflict_ids'], ['original-baseline-owned-backup-unknown', 'finite-time-budget-and-recovery-rights'], 'two whole original storage rights conflicts')
    exact(brief['whole_original_storage_review'], storage, 'whole unchanged383 storage and rights review')
    for key, section, field in [('original320', 'claim_contract', 'original320_claim_contract'), ('original322', 'commit_contract', 'original322_commit_contract'), ('original324', 'baseline_contract', 'original324_baseline_contract')]:
        exact(json.loads(inputs[key])[section], storage[field], 'whole original native clause match ' + key + section)
    for field, key in policy['whole_reference_fields'].items():
        exact(brief[field], sources['inputs'][key], 'whole reference ' + key)
    for key in ['writer_brief390', 'revocation_brief391', 'loss_brief392']:
        prior = json.loads(inputs[key])
        exact(prior['selected_option'], None, 'prior proposal still unselected')
        exact(prior['approved_contract_migration'], None, 'prior migration still inactive')
    exact(brief['boundaries'], plan['boundaries'], 'every original closed boundary')
    for key in ['selected_option', 'approved_contract_migration', 'actual_original_baseline', 'actual_backup_bindings', 'actual_storage_sequence', 'actual_rights_ledger', 'actual_owned_outcomes', 'actual_target_outcomes']:
        exact(brief[key], None, 'inactive or unknown ' + key)
    for key in ['native_authority', 'source_documentation_is_native_proof', 'universal_impossibility_proven', 'current_step_strong_safe_pause']:
        exact(brief[key], False, 'no promotion ' + key)
    for key in ['new_native_proofs', 'new_native_cases']:
        exact(brief[key], 0, 'no native progress')
    exact(brief['whole_original_requirements_remain_normative'], True, 'full original contracts remain binding')
    exact(brief['conditional_close_step'], 398, 'finite close398')
    exact(brief['next_preparable_step_after_complete393_acceptance'], 394, 'actual393 acceptance before394')
    branches = brief['conditional_branch_questions']
    exact([r['source_branch_id'] for r in branches], policy['expected_branch_ids'], 'seven original branch navigation identities')
    original_branches = {r['id']: r for r in storage['original373_recovery_branch_review']}
    for row in branches:
        exact(row['full_original_branch'], original_branches[row['source_branch_id']], 'WHOLE unchanged original branch')
        exact(row['option_id'], 'separate-owned-target-quarantine-hypothesis', 'exact hypothesis branch context')
        exact(row['all_applicable_original_gates_required'], True, 'every original branch gate required')
        for key in ['current_authority', 'is_executable_selector', 'limits_scope_of_whole_original_branches']:
            exact(row[key], False, 'no branch authority dispatch or scope reduction')
        exact(row['actual_condition'], None, 'no actual branch condition')
        exact(row['actual_action_outcome'], None, 'no actual branch effect')
    options = brief['options']
    exact([o['id'] for o in options], policy['expected_option_ids'], 'four explicit original alternatives')
    exact([o['disposition'] for o in options], policy['expected_dispositions'], 'three retention directions and blocked deferral')
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
    exact([r['id'] for r in witnesses], policy['expected_witness_ids'], 'all eight conditional policy witnesses')
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
        'step': 393, 'state': 'prepared-inactive-baseline-storage-brief-user-acceptance-pending',
        'brief': brief, 'whole_entry392': entry, 'whole_input_bindings': sources['inputs'],
        'last_confirmed_repository_pause': 388, 'strong_safe_pause': False,
        'selected_option': None, 'approved_contract_migration': None, 'native_authority': False,
        'conditional_close_step': 398, 'after_actual393_acceptance_next_preparable_step': 394,
        'next_authorized_stage_after398': None,
    }))
