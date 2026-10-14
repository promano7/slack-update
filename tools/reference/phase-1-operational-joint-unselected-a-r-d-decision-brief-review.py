#!/usr/bin/env python3
"""Supplied unselected decision reference; no native selection,approval or authority."""
import hashlib
import json
import re

POLICY_SHA = '0adaee48c47c7595e9ba304add305bdd29a79c463d1bd1bf53055b8488d7e7fa'

def sha(raw):
    return hashlib.sha256(raw).hexdigest()


def canonical(value):
    return sha(json.dumps(value, sort_keys=True, separators=(',', ':'), ensure_ascii=True).encode())


def exact(actual, expected, label):
    if type(actual) is not type(expected):
        raise ValueError(label)
    different = actual != expected if type(actual) is bytes else canonical(actual) != canonical(expected)
    if different:
        raise ValueError(label)
    return True


def pointer(value, path):
    if path == '':
        return value
    if not path.startswith('/'):
        raise ValueError('invalid JSON pointer')
    for encoded in path[1:].split('/'):
        key = encoded.replace('~1', '/').replace('~0', '~')
        if type(value) is list:
            if not re.fullmatch(r'0|[1-9][0-9]*', key) or int(key) >= len(value):
                raise ValueError('invalid list pointer')
            value = value[int(key)]
        else:
            value = value[key]
    return value


def validate_policy(policy):
    return exact(canonical(policy), POLICY_SHA, 'authored417 policy substitution')


def validate_sources(inputs, source_blobs, sources, policy):
    validate_policy(policy)
    exact(canonical(sources), policy['fixture_canonical_sha256']['sources'], 'whole authored417 source registry')
    exact(sorted(inputs), sorted(sources['inputs']), 'all141 whole JSON inputs')
    for key, row in sources['inputs'].items():
        exact(sha(inputs[key]), row['sha256'], 'whole source bytes ' + key)
        exact(canonical(json.loads(inputs[key])), row['canonical_sha256'], 'whole source value ' + key)
    previous = json.loads(inputs['sources416'])
    inherited = {k: v for k, v in sources['inputs'].items() if k not in policy['new_source_keys']}
    exact(inherited, previous['inputs'], 'all137 original input bindings unchanged')
    exact(sources['inert_roots'], previous['inert_roots'], 'all four native roots remain inert')
    exact(sources['reviewer_roots'][:-1], previous['reviewer_roots'], 'all prior reviewer roots unchanged')
    roots = sources['inert_roots'] + sources['reviewer_roots'] + [sources['readme']]
    exact(sorted(source_blobs), sorted(row['path'] for row in roots), 'all43 source roots')
    for row in roots:
        exact(sha(source_blobs[row['path']]), row['sha256'], 'whole root bytes ' + row['path'])
    for row in sources['inert_roots']:
        exact(row['execution_authorized'], False, 'native root never dispatched')
        exact(row['actual_native_binding'], None, 'no native binding')
    return True


def validate_fixtures(fixtures, policy):
    validate_policy(policy)
    exact(sorted(fixtures), sorted(policy['fixture_canonical_sha256']), 'exact authored fixture set')
    for key, value in fixtures.items():
        exact(canonical(value), policy['fixture_canonical_sha256'][key], 'whole authored fixture ' + key)
    return True


def validate_repository(blobs, baseline, policy):
    validate_policy(policy)
    exact(sorted(blobs), sorted(baseline), 'all2258 historical416 paths')
    for path, digest in baseline.items():
        raw = blobs[path]
        if path in policy['prefixes']:
            prefix = policy['prefixes'][path].encode()
            if not raw.startswith(prefix):
                raise ValueError('missing exact417 additive prefix')
            raw = raw[len(prefix):]
        exact(sha(raw), digest, 'unchanged historical416 bytes ' + path)
    return True


def validate_entry(entry,inputs,policy):
    validate_policy(policy);exact(canonical(entry),policy['fixture_canonical_sha256']['entry416'],'WHOLE actual416 entry')
    raw=entry['receipt']['text'].encode('utf-8');exact(sha(raw),entry['receipt']['sha256'],'complete416 transcript SHA');exact(len(raw),entry['receipt']['size_bytes'],'complete416 length')
    exact([s for s in entry['receipt']['text'].splitlines() if s.startswith('PASS: ')],policy['receipt_pass_labels'],'all84 ordered416 PASS')
    exact(re.findall(r'^ create mode 100644 (.+)$',entry['receipt']['text'],re.M),policy['receipt_create_paths'],'eight exact416 creates')
    for marker in policy['receipt_single_markers']:exact(entry['receipt']['text'].count(marker),1,'single416 marker')
    exact(entry['receipt']['text'].split(policy['receipt_push_marker'])[1],policy['receipt_final_tail'],'reported main push empty status matching58c9d1bheads')
    exact(entry['confirmation']['commit_prefix'],'58c9d1b','accepted416 prefix');exact(entry['confirmation']['commit_full'],None,'full user Git ID unknown');exact(entry['confirmation']['new_strong_safe_pause_confirmed'],False,'416 intermediate checkpoint only')
    exact(entry['whole_confirmed415_entry_reference'],policy['expected_prior_entry_reference'],'WHOLE actual prior415 entry');exact(json.loads(inputs['actual415_entry'])['confirmation']['last_confirmed_strong_safe_pause_step'],408,'last confirmed repository pause408 only')
    return True


GATE_IDS = ['explicit-option-decision','independent-joint-specification-and-impact-acceptance','explicit-normative-migration-if-norms-change','actual-composition-selection-and-binding','independent-actual-safety-and-observation-review','fresh-explicit-bounded-native-test-grant','independent-native-conformance-and-later-readiness']


def validate_separate_boundaries(gates,policy):
    validate_policy(policy);exact([r['gate_id'] for r in gates],GATE_IDS,'all seven separate decisions in exact safe order')
    for i,row in enumerate(gates):
        exact(row['previous_separate_boundary'],None if i==0 else GATE_IDS[i-1],'no native grant before independent actual safe review')
        exact(row['current_acceptance_or_authority_present'],False,'no current separate decision/evidence accepted')
        exact(row['actual_evidence_or_decision'],None,'no actual choice/review/grant inferred')
        exact(row['fulfilled_by_step417'],False,'brief does not fulfill a decision gate')
    exact(gates[2]['applies_when'],'if-current-norms-change','migration approval conditional on actual norm change')
    exact([canonical(r) for r in gates],policy['expected_review_row_sha256']['seven_separate_decision_and_evidence_boundaries'],'whole exact decision meanings preserved')
    return True


def validate_whole_attachments(brief,inputs,sources,policy):
    validate_policy(policy);rows=brief['whole_source_attachments']
    exact([[r['source_input_key'],r['json_pointer']] for r in rows],policy['expected_attachment_specs'],'all complete exact source attachments')
    documents={k:json.loads(inputs[k]) for k in {r['source_input_key'] for r in rows}}
    for row in rows:
        exact(row['source_path'],sources['inputs'][row['source_input_key']]['path'],'whole attached source path')
        value=pointer(documents[row['source_input_key']],row['json_pointer'])
        exact(canonical(value),row['canonical_sha256'],'WHOLE attached value includes every original clause/finding/pair/member')
        exact(row['whole_source_value_required'],True,'whole source still required');exact(row['summary_replaces_whole_source'],False,'no concise summary substituted for whole evidence')
    exact([canonical(r) for r in rows],policy['expected_review_row_sha256']['whole_source_attachments'],'authored full attachment registry')
    return True


def validate_brief(brief,inputs,sources,policy):
    validate_policy(policy);exact(brief['schema'],1,'integer schema');exact(brief['step'],417,'integer417')
    exact(brief['state'],'prepared-unselected-a-r-d-decision-reference','prepared unselected brief');exact(brief['scope'],'repository-internal-manuscript-audit409-418-only','same finite scope');exact(brief['entry_commit_prefix'],'58c9d1b','accepted416 entry')
    for key in policy['null_fields']:exact(brief[key],None,'unknown or unselected '+key)
    for key in policy['false_fields']:exact(brief[key],False,'no decision request approval authority completion or pause '+key)
    exact(brief['boundaries'],policy['expected_boundaries'],'complete original closed boundaries');exact(brief['whole_original_requirements_remain_normative'],True,'original norms binding');exact(brief['whole_input_references'],sources['inputs'],'all141 whole input bindings')
    packet=json.loads(inputs['packet407']);previous=json.loads(inputs['audit416']);candidate=json.loads(inputs['candidate400']);plan=json.loads(inputs['plan409'])
    exact(brief['whole_nine_global_semantic_rules'],packet['semantic_register']['rules'],'all nine complete own-actor global rules')
    for field in ['whole_accepted410_findings','whole_accepted410_clarifications','whole_accepted411_findings','whole_accepted412_findings','whole_accepted413_findings','whole_accepted414_findings']:exact(brief[field],previous[field],'WHOLE preceding open record '+field)
    exact(brief['whole_integrated416_finding_reviews'],previous['integrated_finding_reviews'],'all13 WHOLE open findings and all dependency positions,not a summary')
    exact(brief['whole_integrated416_dimension_reviews'],previous['all9_joint_dimension_reviews'],'all9 WHOLE integrated dimensions')
    exact(brief['classification_counts'],previous['classification_counts'],'three changes six conditions four hypotheses unchanged')
    exact(brief['whole_loss_and_incompatibility_register'],packet['complete_guarantee_loss_and_incompatibility_register'],'WHOLE source losses plus forward recovery publication and stage changes')
    exact(brief['whole_four_inactive_repair_reviews'],previous['inactive_repair_dependency_reviews'],'four WHOLE proposals/dependency impacts inactive,history retained')
    exact(brief['interpretation_limit'],policy['expected_interpretation_limit'],'no approval/choice/native evidence inference from repository work or summary')
    alternatives=brief['unselected_alternatives'];exact([r['candidate_id'] for r in alternatives],['JCP400-A','JCP400-R','JCP400-D'],'all three unselected alternatives in review order')
    bases=[candidate,packet['whole400_retention_comparator'],packet['whole400_deferral_comparator']]
    for i,(row,basis) in enumerate(zip(alternatives,bases)):
        exact(row['whole_historical_source_basis'],basis,'WHOLE historical source option/comparator unchanged')
        for key in ['selected','independent_impact_accepted','migration_approved','runtime_authority']:exact(row[key],False,'no alternative selection/acceptance/approval/authority '+key)
        for key in ['actual_implementation_selected','actual_joint_compatibility','actual_native_evidence','fresh_native_test_grant']:exact(row[key],None,'no actual alternative realization or grant '+key)
        original_refs=candidate['draft_option_references'] if i==0 else basis['option_references']
        refs=row['whole_original_option_and_integrated_review_references'];exact([r['whole_original_option_reference'] for r in refs],original_refs,'all full original option references for this path')
        for ref in refs:
            attached=ref['whole_integrated416_option_review_reference'];exact(attached['source_input_key'],'audit416','WHOLE integrated option source')
            source=pointer(previous,attached['json_pointer']);exact(canonical(source),attached['canonical_sha256'],'complete integrated option assessment and full original option')
            original=source['whole_original397_option_register_row'];exact(original['option_id'],ref['whole_original_option_reference']['option_id'],'same original option identity')
            exact(canonical(original['whole_option']),ref['whole_original_option_reference']['whole_option_canonical_sha256'],'WHOLE original clause/trust/loss/effect/failure/platform obligations attached')
        exact(canonical(row),policy['expected_review_row_sha256']['unselected_alternatives'][i],'complete authored consequences losses blockers and finding scope')
    validate_separate_boundaries(brief['seven_separate_decision_and_evidence_boundaries'],policy)
    exact(len(brief['non_authorizing_event_examples']),6,'all six explicit no-inference examples')
    for row in brief['non_authorizing_event_examples']:
        for key in ['actual_current_user_option_choice','native_test_grant']:exact(row[key],None,'illustration supplies no current choice/grant')
        for key in ['independent_impact_acceptance','migration_approval','actual_safe_review_acceptance','operational_readiness','current_pause_confirmation','example_is_native_evidence']:exact(row[key],False,'event does not imply '+key)
    exact([canonical(r) for r in brief['non_authorizing_event_examples']],policy['expected_review_row_sha256']['non_authorizing_event_examples'],'complete non-authorizing meanings')
    exact(brief['remaining_review_and_approval_order'],plan['approval_order'],'whole original actual safety then fresh grant order')
    exact(brief['whole_conditional_pause_policy'],plan['pause_policy'],'WHOLE conditional pause policy separate from native/option decisions')
    exact(brief['freeze_with_options_unselected_permitted_only_after_all_pause_conditions'],True,'repository-only freeze may retain unselected paths but never skip pause conditions')
    exact(brief['conditional_close_step'],418,'conditional418 target');exact(brief['next_preparable_step_after_complete417_acceptance'],418,'complete actual417 before418');exact(brief['no_automatic419'],True,'then STOP noautomatic419')
    validate_whole_attachments(brief,inputs,sources,policy)
    return True


def review(entry,brief,inputs,source_blobs,sources,policy):
    validate_entry(entry,inputs,policy);validate_sources(inputs,source_blobs,sources,policy);validate_brief(brief,inputs,sources,policy)
    return {'step':417,'state':'prepared-unselected-decision-reference-awaiting-user-acceptance','alternatives':3,'separate_boundaries':7,'non_authorizing_examples':6,'whole_attachments':16,'retained_open_findings':13,'classification_counts':{'explicit-guarantee-change':3,'underspecified-condition':6,'unproved-native-hypothesis':4},'runtime_authority':False,'native_cases_run':0,'native_proofs_added':0,'independent_impact_review_accepted':False,'selected_options':None,'selected_candidate':None,'decision_requested_now':False,'approval_requested_by_this_brief':False,'approved_contract_migration':None,'current_strong_safe_pause':False,'last_confirmed_strong_safe_pause_step':408,'actual_host_state':'unobserved-not-claimed-absent','actual_live_bindings':None,'actual_global_host_closure':False,'next_preparable_step_after_complete_acceptance':418}
