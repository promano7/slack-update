#!/usr/bin/env python3
"""Review inactive actor/action trust proposals from supplied data only."""
import hashlib
import json
import re

POLICY_SHA = 'f28308266cfded1bf710b5842054e004673eae3bf6cd2f929e65333608ba79eb'

def sha(raw):
    return hashlib.sha256(raw).hexdigest()


def canonical(value):
    return sha(json.dumps(value, sort_keys=True, separators=(',', ':'), ensure_ascii=True).encode())


def exact(value, expected, label):
    if type(value) is not type(expected) or (value != expected if type(value) is bytes else canonical(value) != canonical(expected)):
        raise ValueError(label)
    return True


def validate_policy(policy):
    return exact(canonical(policy), POLICY_SHA, 'authored401 policy substitution')


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


def validate_entry(entry, policy):
    validate_policy(policy)
    exact(entry['confirmation'], policy['expected_confirmation400'], 'whole accepted400 supplied-return confirmation')
    raw = entry['receipt']['text'].encode('utf-8')
    exact(sha(raw), policy['receipt_sha256'], 'complete disclosed400 transcript SHA')
    exact(len(raw), policy['receipt_size_bytes'], 'complete400 transcript length')
    exact(entry['receipt']['capture_basis'], entry['confirmation']['capture_basis'], 'transcription provenance disclosed')
    exact([s for s in entry['receipt']['text'].splitlines() if s.startswith('PASS: ')], policy['receipt_pass_labels'], 'all59 ordered400 PASS labels')
    exact(re.findall(r'^ create mode 100644 (.+)$', entry['receipt']['text'], re.M), policy['receipt_create_paths'], 'eight400 exact creates')
    for marker in policy['receipt_single_markers']:
        exact(entry['receipt']['text'].count(marker), 1, 'single400 acceptance marker')
    exact(entry['receipt']['text'].split(policy['receipt_push_marker'])[1], policy['receipt_final_tail'], 'reported empty final status and two matching400 heads')
    return True


def validate_sources(inputs, source_blobs, sources, policy):
    validate_policy(policy)
    exact(sorted(inputs), sorted(sources['inputs']), 'all76 whole JSON inputs')
    for key, row in sources['inputs'].items():
        exact(sha(inputs[key]), row['sha256'], 'whole input bytes ' + key)
        exact(canonical(json.loads(inputs[key])), row['canonical_sha256'], 'whole input canonical ' + key)
    previous = json.loads(inputs['sources400'])
    inherited = {k: v for k, v in sources['inputs'].items() if k not in ['candidate400', 'sources400', 'policy400']}
    exact(inherited, previous['inputs'], 'all73 original400 input bindings unchanged')
    exact(sources['previous_readme_binding'], previous['readme'], 'historical399 README binding retained')
    roots = sources['inert_roots'] + sources['reviewer_roots'] + [sources['readme']]
    exact(sorted(source_blobs), sorted(r['path'] for r in roots), 'all27 pure/inert/accepted400 README roots')
    for row in roots:
        exact(sha(source_blobs[row['path']]), row['sha256'], 'whole root bytes ' + row['path'])
    return True


def classify_hypothetical(case, policy):
    """Describe an authored policy witness; never authorize or inspect native effects."""
    validate_policy(policy)
    exact(case['hypothetical_only'], True, 'only authored hypothetical facts')
    exact(case['actual_native_observation'], None, 'no actual observation supplied')
    exact(case['runtime_authority'], False, 'no witness permission')
    member = case['enumerated_for_assumption']
    if member is not None and type(member) is not bool:
        raise ValueError('membership must be bool or unknown')
    known = case['evidence_known_in_hypothesis']
    if type(known) is not bool:
        raise ValueError('hypothetical evidence must be bool')
    actor = case['actor_class']
    action = case['action_class']
    if type(actor) is not str or not actor or action not in policy['hypothetical_action_classes']:
        raise ValueError('unknown witness actor/action syntax')
    if member is None or not known:
        disposition = 'hypothetical-pending-membership-or-evidence'
    elif action == 'ordinary-workload-write' or actor not in policy['hypothetical_infrastructure_classes'] or not member:
        disposition = 'hypothetical-workload-control-required'
    elif action == 'deliberate-infrastructure-tampering':
        disposition = 'outside-inactive-proposed-guarantee-not-authorized'
    elif action == 'ordinary-infrastructure-failure':
        disposition = 'hypothetical-trust-condition-failed-preserve-original-status'
    else:
        disposition = 'hypothetical-assumption-does-not-prove-control'
    if member is None or not known:
        condition = 'unknown'
    elif action == 'ordinary-workload-write' or actor not in policy['hypothetical_infrastructure_classes'] or not member:
        condition = 'not-an-infrastructure-assumption'
    elif action in ['deliberate-infrastructure-tampering','ordinary-infrastructure-failure']:
        condition = 'failed'
    else:
        condition = 'assumed-only-in-hypothesis'
    return {'inactive_proposal_disposition': disposition,
        'hypothetical_trust_condition_status': condition,
        'known_mismatch_cannot_be_erased_by_proposed_exclusion': True,
        'original_all_writer_requirement_unchanged': True,
        'actual_actor_or_support': None, 'runtime_authority': False, 'native_proof': False}

def validate_review_shape(review, inputs, sources, policy):
    validate_policy(policy)
    candidate = json.loads(inputs['candidate400'])
    writer = json.loads(inputs['accepted381dossier'])
    guard = json.loads(inputs['original324'])
    effects = json.loads(inputs['effects'])
    exact(review['schema'], 1, 'integer schema')
    exact(review['step'], 401, 'integer401 step')
    exact(review['state'], 'inactive-joint-writer-source-trust-review', 'inactive proposal state')
    exact(review['scope'], candidate['scope'], 'finite399-408 scope')
    exact(review['candidate_id'], 'JCP400-A', 'unchanged author draft direction')
    exact(review['whole_candidate400_reference'], sources['inputs']['candidate400'], 'whole immutable400candidate retained')
    exact(review['boundaries'], candidate['boundaries'], 'all native/project gates remain closed')
    exact(review['whole_original_requirements_remain_normative'], True, 'whole originals remain normative')
    for name in ['guard_contract','baseline_contract','interstage_contract','resource_domains']:
        exact(review['whole_original_' + name], guard[name], 'whole original324 ' + name)
    exact(review['whole_original_writer_trust_review'], writer['trust_boundary_review'], 'whole original non-exempt writer/trust requirement')
    exact(review['whole_original_independent_resolution_criteria'], writer['independent_resolution_criteria'], 'all original independent writer criteria')
    losses = [r for r in candidate['complete_source_guarantee_loss_register'] if r['option_id'] in ['explicit-trusted-host-boundary','explicit-local-clock-trust-boundary']]
    exact(review['complete400_writer_clock_guarantee_losses'], losses, 'both complete unchanged trust loss lists')
    exact(review['whole400_shared_trust_wording'], candidate['new_joint_wording'][0], 'whole unchanged400 shared trust amendment')
    exact(review['proposed_trusted_infrastructure_roles'], policy['expected_actor_roles'], 'six unselected actual-null actor/action questions')
    exact(review['joint_proposed_statements'], policy['expected_statements'], 'six complete draft scope/identity/lifetime/failure statements')
    domains = review['seven_original_domain_reviews']
    exact([r['whole_original_writer_resource_row'] for r in domains], writer['original_writer_resource_rows'], 'all seven whole original resource rows')
    exact(domains, policy['expected_domains'], 'full source/alias/writer scope not waived')
    classes = writer['trust_boundary_review']['required_writer_classes']
    matrix = review['all_domain_writer_class_questions']
    exact([(r['domain'], r['writer_class']) for r in matrix], [(r['domain'], c) for r in domains for c in classes], 'all84 ordered original domain/class questions')
    exact(matrix, policy['expected_matrix'], 'authored coverage is not native writer inventory')
    for name, original_name in [('whole_lifetime_hazard_reviews','lifetime_hazards'),('whole_effect_domain_reviews','effect_domains')]:
        rows = review[name]
        exact([r['id'] for r in rows], [r['id'] for r in effects[original_name]], 'all whole original IDs and order')
        for index,(row,original) in enumerate(zip(rows,effects[original_name])):
            ref = row['whole_original_reference']
            exact(ref['input_key'], 'effects', 'whole original effects input')
            exact(ref['path'], sources['inputs']['effects']['path'], 'exact original effects path')
            exact(ref['json_pointer'], '/' + original_name + '/' + str(index), 'whole exact original row pointer')
            exact(ref['whole_value_canonical_sha256'], canonical(original), 'whole original row binding')
            exact(pointer(effects, ref['json_pointer']), original, 'whole row not shortened projection')
        exact(rows, policy['expected_original_review_rows'][name], 'substantive unresolved candidate lifetime/consumer controls')
    exact(review['whole_original_platform_writer_domains'], json.loads(inputs['design372'])['separate_platform_writer_domains'], 'both platforms full original14 unknown rows')
    exact(review['authored_hypothetical_classification_cases'], policy['expected_cases'], 'all12 explicit authored paper cases')
    for case in review['authored_hypothetical_classification_cases']:
        exact(classify_hypothetical(case, policy)['inactive_proposal_disposition'], case['expected_inactive_proposal_disposition'], 'supplied policy witness classification')
        exact(classify_hypothetical(case, policy)['hypothetical_trust_condition_status'], case['expected_hypothetical_trust_condition_status'], 'known trust failure survives proposed guarantee exclusion')
    for key in ['selected_options','approved_contract_migration','approved_joint_specification','native_evidence','actual_trust_boundary_members','actual_source_objects','actual_enforcement_policy','actual_owner_loss_and_drained_writers','actual_two_platform_support','after_confirmed408_next_authorized_stage']:
        exact(review[key], None, 'no actual binding selection approval or authority ' + key)
    for key in ['runtime_authority','original_source_lifetime_review_is_exhaustive_native_inventory','infrastructure_role_name_or_uid_proves_trust','ordinary_privileged_workload_exempt','observer_or_injector_exempt','deliberate_trusted_infrastructure_exclusion_is_active','hidden_infrastructure_tampering_detection_proven','guard_reacquisition_or_deadline_renewal_allowed','exact_semantic_migration_complete','independent_impact_review_accepted']:
        exact(review[key], False, 'no trust waiver native claim or renewal ' + key)
    for key in ['native_cases_run','native_proofs_added']:
        exact(review[key], 0, 'zero native progress')
    exact(review['whole_396_impact_reference'], sources['inputs']['oracle_brief396'], 'whole full impact no semantic approval')
    exact(review['remaining_joint_reviews'], candidate['nine_unresolved_joint_reviews'], 'all nine original draft joint questions still unresolved')
    exact(review['next_preparable_step_after_complete401_acceptance'], 402, '402 only after full401 acceptance')
    exact(review['conditional_close_step'], 408, 'same conditional block close')
    exact(review['no_automatic409'], True, 'STOP after confirmed408')
    return True

def validate_fixtures(fixtures, policy):
    validate_policy(policy)
    exact(sorted(fixtures), sorted(policy['fixture_canonical_sha256']), 'exact401 fixture set')
    for name, value in fixtures.items():
        exact(canonical(value), policy['fixture_canonical_sha256'][name], 'whole authored401 fixture ' + name)
    return True


def validate_repository(blobs, baseline, policy):
    validate_policy(policy)
    exact(sorted(blobs), sorted(baseline), 'all2130 historical400 paths')
    for path, digest in baseline.items():
        raw = blobs[path]
        if path in policy['prefixes']:
            addition = policy['prefixes'][path].encode()
            if not raw.startswith(addition):
                raise ValueError('missing exact401 additive prefix')
            raw = raw[len(addition):]
        exact(sha(raw), digest, 'all historical400 bytes unchanged ' + path)
    return True


def review(entry, proposal, inputs, source_blobs, sources, policy):
    validate_entry(entry, policy)
    validate_sources(inputs, source_blobs, sources, policy)
    validate_review_shape(proposal, inputs, sources, policy)
    return {'step':401, 'state':'prepared-inactive-trust-review-user-acceptance-pending',
        'selected_options':None, 'approved_contract_migration':None, 'runtime_authority':False,
        'last_confirmed_repository_pause':398, 'strong_safe_pause':False,
        'after_complete401_acceptance_next_preparable_step':402, 'conditional_close_step':408,
        'after_confirmed408_next_authorized_stage':None}
