#!/usr/bin/env python3
"""Review inactive baseline/storage/once-only-rights drafts from supplied data only."""
import hashlib
import json
import re

POLICY_SHA = 'add02e1e7333b42c5df7fea30d59e02d93f98b29b5a8c76cd3c846cc98c6a1db'

def sha(raw):
    return hashlib.sha256(raw).hexdigest()


def canonical(value):
    return sha(json.dumps(value, sort_keys=True, separators=(',', ':'), ensure_ascii=True).encode())


def exact(value, expected, label):
    if type(value) is not type(expected) or (value != expected if type(value) is bytes else canonical(value) != canonical(expected)):
        raise ValueError(label)
    return True


def validate_policy(policy):
    return exact(canonical(policy), POLICY_SHA, 'authored404 policy substitution')


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
    exact(entry['confirmation'], policy['expected_confirmation403'], 'whole accepted403 supplied-return confirmation')
    raw = entry['receipt']['text'].encode('utf-8')
    exact(sha(raw), policy['receipt_sha256'], 'complete disclosed403 transcript SHA')
    exact(len(raw), policy['receipt_size_bytes'], 'complete403 transcript length')
    exact(entry['receipt']['capture_basis'], entry['confirmation']['capture_basis'], 'transcription provenance disclosed')
    exact([s for s in entry['receipt']['text'].splitlines() if s.startswith('PASS: ')], policy['receipt_pass_labels'], 'all73 ordered403 PASS labels')
    exact(re.findall(r'^ create mode 100644 (.+)$', entry['receipt']['text'], re.M), policy['receipt_create_paths'], 'eight403 exact creates')
    for marker in policy['receipt_single_markers']:
        exact(entry['receipt']['text'].count(marker), 1, 'single403 acceptance marker')
    exact(entry['receipt']['text'].split(policy['receipt_push_marker'])[1], policy['receipt_final_tail'], 'reported empty final status and two matching403 heads')
    return True


def validate_sources(inputs, source_blobs, sources, policy):
    validate_policy(policy)
    exact(sorted(inputs), sorted(sources['inputs']), 'all85 whole JSON inputs')
    for key, row in sources['inputs'].items():
        exact(sha(inputs[key]), row['sha256'], 'whole input bytes ' + key)
        exact(canonical(json.loads(inputs[key])), row['canonical_sha256'], 'whole input canonical ' + key)
    previous = json.loads(inputs['sources403'])
    inherited = {k: v for k, v in sources['inputs'].items() if k not in ['loss403', 'sources403', 'policy403']}
    exact(inherited, previous['inputs'], 'all82 original403 input bindings unchanged')
    exact(sources['previous_readme_binding'], previous['readme'], 'historical399 README binding retained')
    roots = sources['inert_roots'] + sources['reviewer_roots'] + [sources['readme']]
    exact(sorted(source_blobs), sorted(r['path'] for r in roots), 'all30 pure/inert/accepted403 README roots')
    for row in roots:
        exact(sha(source_blobs[row['path']]), row['sha256'], 'whole root bytes ' + row['path'])
    return True


def hypothetical_case(case,policy):
    """Describe a paper NEW-action question; never select or execute recovery."""
    validate_policy(policy);exact(case['hypothetical_only'],True,'paper facts only')
    exact(case['actual_native_evidence'],None,'no actual facts in paper case');exact(case['runtime_authority'],False,'no action rights')
    for key,values in policy['paper_enum_fields'].items():
        if type(case[key]) is not str or case[key] not in values: raise ValueError('invalid scoped paper classification')
    for key in policy['paper_bool_fields']:
        if case[key] is not None and type(case[key]) is not bool: raise ValueError('bool/unknown required')
    for key in ['original_budget','original_spent']:
        if case[key] is not None and (type(case[key]) is not int or case[key]<0): raise ValueError('integer/unknown original budget required')
    captured=case['captured_target_status'] if case['qualified_full_original_vectors'] is True else 'unknown'
    if case['restore_outcome']=='unknown':q='paper-deny-repeat-uncertain-restore'
    elif captured=='known-foreign-drift':q='paper-deny-foreign-drift'
    elif case['claim_status']!='known-consumed-active' or case['launch_status']!='known-spent':q='paper-deny-unknown-original-claim-or-launch'
    elif case['action_spend_status']=='unknown':q='paper-deny-unknown-action-spend'
    elif case['action_spend_status']=='known-spent':q='paper-deny-new-use-of-spent-action'
    elif case['durable_budget_known'] is not True or case['recovery_scope_time_known'] is not True or case['original_budget'] is None or case['original_spent'] is None or case['original_spent']>=case['original_budget']:q='paper-deny-budget-or-time'
    elif case['recovery_revoked'] is not False:q='paper-deny-new-recovery-admission'
    elif any(case[k] is not True for k in ['guard_identity_known','full_drain_known','original_source_and_backend_equivalence_known']):q='paper-deny-incomplete-control-drain-or-source'
    elif captured=='unknown':q='paper-deny-unknown-target-no-safe-restore'
    elif captured=='known-original':q='paper-no-target-write-verification-question'
    elif case['restore_outcome']=='known-complete':q='paper-deny-repeat-known-complete-restore'
    elif case['backup_status']!='known-exact-original':q='paper-deny-unknown-or-absent-backup'
    else:q='paper-once-only-pre-spend-restore-review-question'
    return {'new_operation_review_question':q,'qualified_captured_target_fact':captured,
        'owned_outcome_preserved':case['owned_outcome'],'controller_outcome_preserved':case['controller_outcome'],
        'original_failure_preserved':case['original_forward_failed'] is True,'known_mismatch_preserved':case['known_mismatch'] is True,
        'actual_native_fact_or_action':None,'runtime_authority':False,'native_proof':False,'actual_closed':False}

def validate_review_shape(review,inputs,sources,policy):
    validate_policy(policy);candidate=json.loads(inputs['candidate400']);design=json.loads(inputs['design373'])
    admission=json.loads(inputs['original320']);commit=json.loads(inputs['original322']);guard=json.loads(inputs['original324']);rights=json.loads(inputs['original323'])
    exact(review['schema'],1,'integer schema');exact(review['step'],404,'integer404')
    exact(review['state'],'inactive-joint-baseline-storage-once-only-rights-review','inactive proposal')
    exact(review['scope'],candidate['scope'],'finite399-408scope');exact(review['candidate_id'],'JCP400-A','same author draft')
    exact(review['boundaries'],candidate['boundaries'],'all original closed gates');exact(review['whole_original_requirements_remain_normative'],True,'original norms stay binding')
    for key,source in [('whole_candidate400_reference','candidate400'),('whole_accepted401_trust_reference','trust401'),('whole_accepted402_operation_reference','operation402'),('whole_accepted403_loss_reference','loss403'),('whole_396_impact_reference','oracle_brief396')]:exact(review[key],sources['inputs'][source],'whole source '+source)
    for key,original,names in [('whole_original320_claim_and_launch',admission,['grant_validation','service_traps','burn_boundary','claim_contract','launch_contract','unknown_rule','failure_cases']),('whole_original322_owned_commit',commit,['commit_contract','owned_paths','successor_stage7','split']),('whole_original324_baseline_guard_interstage',guard,['baseline_contract','guard_contract','interstage_contract','pkglist_contract','recovery_contract','publication_contract']),('whole_original323_recovery_clock_closure',rights,['recovery_contract','clock_contract','closure_contract'])]:exact(review[key],{k:original[k] for k in names},'whole original claim/commit/guard/rights scopes')
    exact(review['whole_original383_independent_resolution_criteria'],json.loads(inputs['accepted383dossier'])['independent_resolution_criteria'],'all original independent storage criteria')
    for key,name in [('whole_original7_baseline_domain_reviews','baseline_domain_review'),('whole_original8_owned_failure_reviews','original_owned_failure_review'),('whole_original16_phase_observation_rows','proposed_phase_observation_rows'),('whole_original16_successor_sequence','full_original_successor_sequence324')]:exact(review[key],design[name],'whole original domain/failure/phase/sequence')
    exact([r['whole_original_microstep_review'] for r in review['all9_owned_microstep_reconciliations']],design['owned_microstep_review'],'ALL9 WHOLE original microsteps and cut questions')
    exact(review['all9_owned_microstep_reconciliations'],policy['expected_microsteps'],'all9 specific candidate microstep constraints')
    exact([r['whole_original_branch'] for r in review['all18_original_recovery_branch_reconciliations']],design['recovery_branch_review'],'ALL18 WHOLE original branch conditions/dispositions')
    exact(review['all18_original_recovery_branch_reconciliations'],policy['expected_branches'],'all18 candidate reconciliations,no hidden recoveryrevocation migration')
    exact(review['whole400_durable_rights_quarantine_wording'],candidate['new_joint_wording'][3],'whole400durableledger/quarantine joint hypothesis')
    exact(review['whole393_storage_option_hypotheses'],[o for o in json.loads(inputs['storage_brief393'])['options'] if o['id'] in ['external-durable-rights-ledger-hypothesis','separate-owned-target-quarantine-hypothesis']],'two WHOLE393storage hypotheses')
    exact(review['joint_proposed_statements'],policy['expected_statements'],'nine complete capture/storage/once-only joint statements')
    exact(review['whole_original_platform_storage_readiness'],design['platform_readiness'],'both platforms original storage support unknown')
    for key in ['actual_original_baseline','actual_protected_backups','actual_owned_commit_or_storage','actual_rights_ledger_or_action_spends','actual_native_evidence','selected_options','approved_joint_specification','approved_contract_migration','after_confirmed408_next_authorized_stage']:exact(review[key],None,'no invented actual state/selection/approval '+key)
    for key in ['missing_backup_proves_unchanged','unknown_owned_implies_target_absent','ACK_hash_or_file_flush_is_durability_proof','logical_pkglist_equivalence_rebinds_raw_bytes','unknown_action_can_repeat','unknown_spend_can_refund','captured_target_fact_erased_by_unrelated_unknown','restore_success_erases_original_failure','is_executable_recovery_selector','semantic_migration_complete','independent_impact_review_accepted','runtime_authority']:exact(review[key],False,'no unsafe shortcut or native/approval claim '+key)
    for key in ['native_cases_run','native_proofs_added']:exact(review[key],0,'zero native progress')
    exact(review['remaining_joint_reviews'],candidate['nine_unresolved_joint_reviews'],'all nine joint blockers unresolved')
    exact(review['authored_hypothetical_cases'],policy['expected_cases'],'all24 explicit paper questions')
    for case in review['authored_hypothetical_cases']:exact(hypothetical_case(case,policy)['new_operation_review_question'],case['expected_question'],'paper original once-only safety question')
    exact(review['next_preparable_step_after_complete404_acceptance'],405,'405after full404acceptance');exact(review['conditional_close_step'],408,'same finite close');exact(review['no_automatic409'],True,'STOPafter408')
    return True

def validate_fixtures(fixtures, policy):
    validate_policy(policy)
    exact(sorted(fixtures), sorted(policy['fixture_canonical_sha256']), 'exact404 fixture set')
    for name, value in fixtures.items():
        exact(canonical(value), policy['fixture_canonical_sha256'][name], 'whole authored404 fixture ' + name)
    return True


def validate_repository(blobs, baseline, policy):
    validate_policy(policy)
    exact(sorted(blobs), sorted(baseline), 'all2154 historical403 paths')
    for path, digest in baseline.items():
        raw = blobs[path]
        if path in policy['prefixes']:
            addition = policy['prefixes'][path].encode()
            if not raw.startswith(addition):
                raise ValueError('missing exact404 additive prefix')
            raw = raw[len(addition):]
        exact(sha(raw), digest, 'all historical403 bytes unchanged ' + path)
    return True


def review(entry,proposal,inputs,source_blobs,sources,policy):
    validate_entry(entry,policy);validate_sources(inputs,source_blobs,sources,policy);validate_review_shape(proposal,inputs,sources,policy)
    return {'step':404,'state':'prepared-inactive-storage-rights-review-user-acceptance-pending','selected_options':None,'approved_contract_migration':None,'runtime_authority':False,'last_confirmed_repository_pause':398,'strong_safe_pause':False,'after_complete404_acceptance_next_preparable_step':405,'conditional_close_step':408,'after_confirmed408_next_authorized_stage':None}
