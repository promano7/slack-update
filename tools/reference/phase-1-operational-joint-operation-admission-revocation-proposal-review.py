#!/usr/bin/env python3
"""Review inactive scoped operation drafts from supplied data only."""
import hashlib
import json
import re

POLICY_SHA = '6c5d23e81a5d3d8e72cb35773c228b95bdab6e2736c483f151561a2751e37982'

def sha(raw):
    return hashlib.sha256(raw).hexdigest()


def canonical(value):
    return sha(json.dumps(value, sort_keys=True, separators=(',', ':'), ensure_ascii=True).encode())


def exact(value, expected, label):
    if type(value) is not type(expected) or (value != expected if type(value) is bytes else canonical(value) != canonical(expected)):
        raise ValueError(label)
    return True


def validate_policy(policy):
    return exact(canonical(policy), POLICY_SHA, 'authored402 policy substitution')


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
    exact(entry['confirmation'], policy['expected_confirmation401'], 'whole accepted401 supplied-return confirmation')
    raw = entry['receipt']['text'].encode('utf-8')
    exact(sha(raw), policy['receipt_sha256'], 'complete disclosed401 transcript SHA')
    exact(len(raw), policy['receipt_size_bytes'], 'complete401 transcript length')
    exact(entry['receipt']['capture_basis'], entry['confirmation']['capture_basis'], 'transcription provenance disclosed')
    exact([s for s in entry['receipt']['text'].splitlines() if s.startswith('PASS: ')], policy['receipt_pass_labels'], 'all60 ordered401 PASS labels')
    exact(re.findall(r'^ create mode 100644 (.+)$', entry['receipt']['text'], re.M), policy['receipt_create_paths'], 'eight401 exact creates')
    for marker in policy['receipt_single_markers']:
        exact(entry['receipt']['text'].count(marker), 1, 'single401 acceptance marker')
    exact(entry['receipt']['text'].split(policy['receipt_push_marker'])[1], policy['receipt_final_tail'], 'reported empty final status and two matching401 heads')
    return True


def validate_sources(inputs, source_blobs, sources, policy):
    validate_policy(policy)
    exact(sorted(inputs), sorted(sources['inputs']), 'all79 whole JSON inputs')
    for key, row in sources['inputs'].items():
        exact(sha(inputs[key]), row['sha256'], 'whole input bytes ' + key)
        exact(canonical(json.loads(inputs[key])), row['canonical_sha256'], 'whole input canonical ' + key)
    previous = json.loads(inputs['sources401'])
    inherited = {k: v for k, v in sources['inputs'].items() if k not in ['trust401', 'sources401', 'policy401']}
    exact(inherited, previous['inputs'], 'all76 original401 input bindings unchanged')
    exact(sources['previous_readme_binding'], previous['readme'], 'historical399 README binding retained')
    roots = sources['inert_roots'] + sources['reviewer_roots'] + [sources['readme']]
    exact(sorted(source_blobs), sorted(r['path'] for r in roots), 'all28 pure/inert/accepted401 README roots')
    for row in roots:
        exact(sha(source_blobs[row['path']]), row['sha256'], 'whole root bytes ' + row['path'])
    return True


def hypothetical_case(case, policy):
    """Compare paper declarations only; do not grant or perform an operation."""
    validate_policy(policy)
    exact(case['hypothetical_only'], True, 'paper declarations only')
    exact(case['runtime_authority'], False, 'case grants no runtime permission')
    exact(case['actual_native_evidence'], None, 'no native observations in paper case')
    scope, revoked = case['scope'], case['revocation_scope']
    if scope not in ['forward','recovery','publication'] or revoked not in ['none','forward','recovery','all','unknown']:
        raise ValueError('invalid original scope declaration')
    bool_keys = ['publication_policy_revoked','admitted','admission_before_request','clock_identity_known','original_spend_known','complete_envelope_known','scope_failed','original_forward_failed','known_original_mismatch','worker_channel_present']
    for key in bool_keys:
        if case[key] is not None and type(case[key]) is not bool:
            raise ValueError('bool/unknown field type required')
    for key in ['effect_tick','deadline_tick']:
        if case[key] is not None and (type(case[key]) is not int or case[key] < 0):
            raise ValueError('synthetic integer/unknown tick required')
    applies = case['publication_policy_revoked'] if scope == 'publication' else revoked == 'all' or revoked == scope
    request_unknown = (case['publication_policy_revoked'] is None) if scope == 'publication' else revoked == 'unknown'
    original = 'original-revocation-scope-unknown-pending' if request_unknown else ('original-applicable-revocation-denies-effects' if applies else 'original-native-preconditions-still-unproved')
    known_failures = []
    if case['known_original_mismatch'] is True: known_failures.append('known-original-mismatch')
    if case['original_forward_failed'] is True: known_failures.append('original-forward-failure')
    expired = case['effect_tick'] is not None and case['deadline_tick'] is not None and case['effect_tick'] >= case['deadline_tick']
    if expired: known_failures.append('fixed-deadline-expired')
    if case['scope_failed'] is True: known_failures.append('scope-failure')
    if case['worker_channel_present'] is True: known_failures.append('forbidden-worker-channel')
    unknown = request_unknown or any(case[k] is None for k in bool_keys + ['effect_tick','deadline_tick']) or any(case[k] is not True for k in ['clock_identity_known','original_spend_known','complete_envelope_known'])
    if case['worker_channel_present'] is True: proposed = 'paper-deny-worker-channel'
    elif expired: proposed = 'paper-deny-expired'
    elif case['scope_failed'] is True: proposed = 'paper-deny-scope-failure'
    elif scope == 'forward' and (case['original_forward_failed'] is True or case['known_original_mismatch'] is True): proposed = 'paper-deny-original-forward-failure'
    elif unknown: proposed = 'paper-pending-unknown-input'
    elif not case['admitted']: proposed = 'paper-deny-new-scope-admission' if applies else 'paper-new-admission-question-not-effect-permission'
    elif applies and not case['admission_before_request']: proposed = 'paper-deny-invalid-admission-order'
    elif applies: proposed = 'paper-admitted-continuation-after-request'
    else: proposed = 'paper-bounded-pre-admitted-envelope'
    return {'proposed_disposition':proposed,'original_revocation_disposition':original,
        'known_failures_preserved':known_failures,'pending_inputs_present':unknown,
        'actual_native_admission_or_drain':None,'actual_closed':False,
        'runtime_authority':False,'native_proof':False}

def validate_review_shape(review, inputs, sources, policy):
    validate_policy(policy)
    candidate=json.loads(inputs['candidate400']);prior=json.loads(inputs['trust401'])
    contract=json.loads(inputs['original323']);bootstrap=json.loads(inputs['original321'])
    exact(review['schema'],1,'integer schema');exact(review['step'],402,'integer402')
    exact(review['state'],'inactive-scoped-operation-revocation-proposal','inactive exact state')
    exact(review['scope'],candidate['scope'],'finite399-408 scope')
    exact(review['candidate_id'],'JCP400-A','same author draft direction')
    exact(review['boundaries'],candidate['boundaries'],'all closed original gates')
    exact(review['whole_original_requirements_remain_normative'],True,'all current original clauses remain normative')
    for key,source in [('whole_candidate400_reference','candidate400'),('whole_accepted401_trust_reference','trust401'),('whole_396_impact_reference','oracle_brief396'),('whole_original30_crossclosure_rows_reference','original327')]:
        exact(review[key],sources['inputs'][source],'whole source reference ' + source)
    exact(review['whole_original323_contracts'],{k:contract[k] for k in ['fence_contract','forward_contract','recovery_contract','clock_contract','closure_contract']},'whole original finite scope clauses')
    exact(review['whole_original321_bootstrap_authentication_fd_loss'],{k:bootstrap[k] for k in ['bootstrap','authentication','fd_policy','loss_policy']},'WHOLE original no-worker-channel321 contracts')
    exact(review['whole_original380_independent_resolution_criteria'],json.loads(inputs['accepted380dossier'])['independent_resolution_criteria'],'all original independent serialization criteria')
    exact(review['whole400_operation_wording'],candidate['new_joint_wording'][1],'whole400 operation wording unchanged')
    exact(review['unchanged400_source_admission_losses'],next(r for r in candidate['complete_source_guarantee_loss_register'] if r['option_id']=='declared-operation-admission-cuts'),'all existing400 source losses retained')
    rows=review['exact_inactive_clause_replacements']
    exact(rows,policy['expected_replacements'],'eight complete draft replacements and exact original clauses')
    for row in rows:
        exact(row['path'],sources['inputs']['original323']['path'],'exact original clause source path')
        exact(pointer(contract,row['json_pointer']),row['whole_current_clause'],'whole original current clause not rewritten')
    for key in ['additional_joint_guarantee_losses','scope_revocation_policy','complete_operation_envelope_requirements']:
        exact(review[key],policy['expected_sections'][key],'complete scope/loss/envelope ' + key)
    nodes=json.loads(inputs['original325'])
    exact([r['whole_original_node'] for r in review['whole_original30_node_questions']],nodes['catalogue_nodes'],'all30 whole original nodes')
    exact(review['whole_original30_node_questions'],policy['expected_nodes'],'no actual native operation partition inferred')
    exact(review['whole_original95_edges'],nodes['catalogue_edges'],'all95 ordered graph edges retained')
    exact(review['whole_original9_authority_windows'],json.loads(inputs['original327'])['authority_windows'],'all9 whole original authority windows')
    exact(review['remaining_joint_reviews'],candidate['nine_unresolved_joint_reviews'],'all nine joint blockers remain unresolved')
    for key in ['selected_options','approved_joint_specification','approved_contract_migration','actual_operation_partition','actual_native_enforcer_or_transport','actual_native_evidence','after_confirmed408_next_authorized_stage']:
        exact(review[key],None,'no invented selection binding or approval ' + key)
    for key in ['policy_admission_launch_bootstrap_service_windows_amended','evidence_has_its_own_new_grant','safe_stop_known_from_request_or_backend_exit','native_no_channel_enforcement_resolved','semantic_migration_complete','independent_impact_review_accepted','runtime_authority']:
        exact(review[key],False,'no hidden policy waiver/native claim ' + key)
    for key in ['target_evidence_uses_original_retained_recovery_scope','publication_evidence_uses_separate_original_publication_controls','original_forward_failure_survives_recovery_and_publication','no_automatic409']:
        exact(review[key],True,'required retained distinction ' + key)
    for key in ['native_cases_run','native_proofs_added']:exact(review[key],0,'zero native progress')
    exact(review['authored_hypothetical_cases'],policy['expected_cases'],'all23 explicit paper cases')
    for case in review['authored_hypothetical_cases']:
        result=hypothetical_case(case,policy)
        exact(result['proposed_disposition'],case['expected_proposed_disposition'],'paper proposed scope result')
        exact(result['original_revocation_disposition'],case['expected_original_revocation_disposition'],'current original revocation distinction')
    exact(review['next_preparable_step_after_complete402_acceptance'],403,'403 only after complete402acceptance')
    exact(review['conditional_close_step'],408,'same finite close408')
    return True

def validate_fixtures(fixtures, policy):
    validate_policy(policy)
    exact(sorted(fixtures), sorted(policy['fixture_canonical_sha256']), 'exact402 fixture set')
    for name, value in fixtures.items():
        exact(canonical(value), policy['fixture_canonical_sha256'][name], 'whole authored402 fixture ' + name)
    return True


def validate_repository(blobs, baseline, policy):
    validate_policy(policy)
    exact(sorted(blobs), sorted(baseline), 'all2138 historical401 paths')
    for path, digest in baseline.items():
        raw = blobs[path]
        if path in policy['prefixes']:
            addition = policy['prefixes'][path].encode()
            if not raw.startswith(addition):
                raise ValueError('missing exact402 additive prefix')
            raw = raw[len(addition):]
        exact(sha(raw), digest, 'all historical401 bytes unchanged ' + path)
    return True


def review(entry, proposal, inputs, source_blobs, sources, policy):
    validate_entry(entry,policy);validate_sources(inputs,source_blobs,sources,policy)
    validate_review_shape(proposal,inputs,sources,policy)
    return {'step':402,'state':'prepared-inactive-operation-review-user-acceptance-pending',
        'selected_options':None,'approved_contract_migration':None,'runtime_authority':False,
        'last_confirmed_repository_pause':398,'strong_safe_pause':False,
        'after_complete402_acceptance_next_preparable_step':403,'conditional_close_step':408,
        'after_confirmed408_next_authorized_stage':None}
