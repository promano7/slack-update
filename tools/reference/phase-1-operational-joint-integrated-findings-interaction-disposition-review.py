#!/usr/bin/env python3
"""Supplied joint findings/dependencies review; no native compatibility or authority."""
import hashlib
import json
import re

POLICY_SHA = '616c66a3cc2d3c96ac37fff3107332022cb89df1aff5f208e5963672b9275f41'

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
    return exact(canonical(policy), POLICY_SHA, 'authored416 policy substitution')


def validate_sources(inputs, source_blobs, sources, policy):
    validate_policy(policy)
    exact(canonical(sources), policy['fixture_canonical_sha256']['sources'], 'whole authored416 source registry')
    exact(sorted(inputs), sorted(sources['inputs']), 'all137 whole JSON inputs')
    for key, row in sources['inputs'].items():
        exact(sha(inputs[key]), row['sha256'], 'whole source bytes ' + key)
        exact(canonical(json.loads(inputs[key])), row['canonical_sha256'], 'whole source value ' + key)
    previous = json.loads(inputs['sources415'])
    inherited = {k: v for k, v in sources['inputs'].items() if k not in policy['new_source_keys']}
    exact(inherited, previous['inputs'], 'all133 original input bindings unchanged')
    exact(sources['inert_roots'], previous['inert_roots'], 'all four native roots remain inert')
    exact(sources['reviewer_roots'][:-1], previous['reviewer_roots'], 'all prior reviewer roots unchanged')
    roots = sources['inert_roots'] + sources['reviewer_roots'] + [sources['readme']]
    exact(sorted(source_blobs), sorted(row['path'] for row in roots), 'all42 source roots')
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
    exact(sorted(blobs), sorted(baseline), 'all2250 historical415 paths')
    for path, digest in baseline.items():
        raw = blobs[path]
        if path in policy['prefixes']:
            prefix = policy['prefixes'][path].encode()
            if not raw.startswith(prefix):
                raise ValueError('missing exact416 additive prefix')
            raw = raw[len(prefix):]
        exact(sha(raw), digest, 'unchanged historical415 bytes ' + path)
    return True


FINDING_IDS = ['A410-01','A410-02','A410-03','A410-04','A410-05','A410-06','A410-07','A411-01','A411-02','A412-01','A412-02','A413-01','A414-01']
REPAIR_IDS = ['CL410-CLOCK','CL410-PUBLICATION','A411-01-INACTIVE','A414-01-INACTIVE']


def joint_paper_status(case,dimension_ids):
    """Keep supplied local paper facts/issues separate; never native compatibility."""
    exact(case['basis'],'authored-hypothetical-joint-review-not-native-evidence','paper basis')
    exact(sorted(case['local_dimension_status']),sorted(dimension_ids),'all nine original dimensions')
    exact(case['retained_finding_ids'],FINDING_IDS,'all13 original findings retained after proposed repair')
    exact(case['normative_activation'],False,'repair never activates a clause')
    failure=case['original_forward_failed']
    if failure is not None and type(failure) is not bool:raise ValueError('original failure strict boolean or null')
    failed=[];unknown=[]
    for id_ in dimension_ids:
        status=case['local_dimension_status'][id_]
        if status is not None and type(status) is not bool:raise ValueError('local paper status strict boolean or null')
        if status is False:failed.append(id_)
        elif status is None:unknown.append(id_)
    for id_ in case['inactive_repairs_considered']:
        if id_ not in REPAIR_IDS:raise ValueError('unknown inactive paper repair')
    return {'known_failed_local_dimensions':failed,'unknown_local_dimensions':unknown,
            'all_local_paper_declarations_positive':not failed and not unknown,
            'qualified_paper_facts':case['qualified_paper_facts'],
            'pending_obligations':case['pending_obligations'],
            'original_forward_failed':failure,'original_failure_erased':False,
            'retained_finding_ids':case['retained_finding_ids'],
            'inactive_repairs_considered':case['inactive_repairs_considered'],
            'repair_closes_original_findings':False,'normative_activation':False,
            'actual_joint_compatibility':None,'native_proof':False,
            'independent_impact_acceptance':False,'runtime_authority':False}


def validate_entry(entry,inputs,policy):
    validate_policy(policy);exact(canonical(entry),policy['fixture_canonical_sha256']['entry415'],'WHOLE actual415 entry')
    raw=entry['receipt']['text'].encode('utf-8');exact(sha(raw),entry['receipt']['sha256'],'complete415 transcript SHA');exact(len(raw),entry['receipt']['size_bytes'],'complete415 length')
    exact([s for s in entry['receipt']['text'].splitlines() if s.startswith('PASS: ')],policy['receipt_pass_labels'],'all89 ordered415 PASS')
    exact(re.findall(r'^ create mode 100644 (.+)$',entry['receipt']['text'],re.M),policy['receipt_create_paths'],'eight exact415 creates')
    for marker in policy['receipt_single_markers']:exact(entry['receipt']['text'].count(marker),1,'single415 marker')
    exact(entry['receipt']['text'].split(policy['receipt_push_marker'])[1],policy['receipt_final_tail'],'reported main push empty status matching51036abheads')
    exact(entry['confirmation']['commit_prefix'],'51036ab','accepted415 prefix');exact(entry['confirmation']['commit_full'],None,'full user Git ID unknown');exact(entry['confirmation']['new_strong_safe_pause_confirmed'],False,'415 intermediate checkpoint only')
    exact(entry['whole_confirmed414_entry_reference'],policy['expected_prior_entry_reference'],'WHOLE actual prior414 entry');exact(json.loads(inputs['actual414_entry'])['confirmation']['last_confirmed_strong_safe_pause_step'],408,'last confirmed repository pause408 only')
    return True


def validate_pair_review(row,original,candidate,option_reviews,expected_sha):
    exact(row['whole_original397_pair_question'],original,'WHOLE original pair question including historical disposition')
    exact(row['whole_inactive407_candidate_pair_question'],candidate,'WHOLE inactive candidate question or absent original pair')
    exact(row['ordered_option_ids'],original['option_ids'],'ordered original option pair,no substitution')
    sides=[]
    for p,id_,digest in zip(row['whole_option_register_pointers'],original['option_ids'],original['whole_option_canonical_sha256']):
        matched=[x for x in option_reviews if x['option_register_pointer']==p]
        exact(len(matched),1,'whole option pointer bound once');side=matched[0];source=side['whole_original397_option_register_row']
        exact(source['option_id'],id_,'exact option side');exact(canonical(source['whole_option']),digest,'whole original source option not label-only');sides.append(side)
    exact(len(row['whole_option_register_pointers']),2,'both whole option sides required')
    exact(row['both_complete_option_scope_assessments'],[s['authored_scope_assessment'] for s in sides],'both full scope assessments retained')
    if candidate is not None:exact(candidate['whole_original397_pair_question'],original,'candidate retains exact historical pair baseline')
    exact(row['same_source_brief'],sides[0]['whole_original397_option_register_row']['input_key']==sides[1]['whole_original397_option_register_row']['input_key'],'actual source family relation')
    exact(row['author_candidate_pair'],candidate is not None,'inactive candidate coverage distinct from selection')
    exact(row['historical_same_brief_label_is_mutual_exclusion_proof'],False,'historical label not proven universal exclusion')
    exact(row['all_other_global_dependencies_still_required'],True,'pair local focus no global waiver')
    exact(row['actual_joint_compatibility'],None,'actual joint compatibility unknown')
    for key in ['native_compatibility_proven','independently_accepted','joint_specification_approved','runtime_authority']:exact(row[key],False,'no pair proof/acceptance/approval/authority '+key)
    exact(canonical(row),expected_sha,'complete authored pair interaction and finding focus')
    return True


def validate_member_dependency(row,original415,reference_pointer,repair_reviews,expected_sha):
    reference=row['whole_415_member_review_reference'];exact(reference['source_input_key'],'audit415','complete accepted415 supplied source')
    exact(reference['json_pointer'],reference_pointer,'all1286 member dependencies in original category/member order')
    member=pointer(original415,reference_pointer);m=member['whole_frozen407_member']
    exact(canonical(member),reference['canonical_sha256'],'WHOLE415 source row including original complete criteria')
    exact(row['member_id'],m['member_id'],'exact dependency member identity')
    exact(row['open_finding_ids_in_415_local_focus'],member['open_findings_in_local_focus'],'all prior local finding dependencies,not a sampled subset')
    repairs=[r['repair_id'] for r in repair_reviews if set(r['affected_global_rule_ids'])&set(member['local_rule_ids_reviewed'])]
    exact(row['inactive_repair_ids_requiring_impact_revisit'],repairs,'exact potential repair impacts reopen full expectations')
    for key in ['all_local_rules_and_complete_original_criteria_still_required','local_focus_not_global_dependency_waiver']:exact(row[key],True,'retain global and full original member dependencies')
    for key in ['original_finding_history_erased','semantic_migration_independently_accepted','runtime_authority']:exact(row[key],False,'no dependency history erasure/independent acceptance/authority')
    exact(row['actual_native_evidence'],None,'no actual dependency evidence')
    exact(canonical(row),expected_sha,'exact authored member dependency disposition')
    return True


def validate_audit(audit,inputs,sources,policy):
    validate_policy(policy);exact(audit['schema'],1,'integer schema');exact(audit['step'],416,'integer416')
    exact(audit['state'],'prepared-internal-integrated-findings-interaction-dispositions','prepared internal integration');exact(audit['scope'],'repository-internal-manuscript-audit409-418-only','same finite scope');exact(audit['entry_commit_prefix'],'51036ab','accepted415 entry')
    for key in policy['null_fields']:exact(audit[key],None,'unknown or unselected '+key)
    for key in policy['false_fields']:exact(audit[key],False,'no authority approval completion or pause '+key)
    exact(audit['boundaries'],policy['expected_boundaries'],'complete original closed boundaries');exact(audit['whole_original_requirements_remain_normative'],True,'original norms binding');exact(audit['whole_input_references'],sources['inputs'],'all137 whole input bindings')
    packet=json.loads(inputs['packet407']);previous=json.loads(inputs['audit415']);original397=json.loads(inputs['packet397'])
    exact(audit['whole_nine_global_semantic_rules'],packet['semantic_register']['rules'],'all nine complete global own-actor requirements')
    fields=['whole_accepted410_findings','whole_accepted411_findings','whole_accepted412_findings','whole_accepted413_findings','whole_accepted414_findings']
    for field in fields+['whole_accepted410_clarifications']:exact(audit[field],previous[field],'WHOLE preceding open record '+field)
    exact(audit['new_findings'],[],'no invented extra defect or resolution from integration')
    exact(audit['interpretation_limit'],policy['expected_interpretation_limit'],'local positivity/counts/labels/repair not compatibility or independent acceptance')
    exact(audit['remaining_review_and_approval_order'],json.loads(inputs['plan409'])['approval_order'],'actual safe independent joint review then separate fresh native grant')
    exact(audit['conditional_close_step'],418,'conditional418 target');exact(audit['next_preparable_step_after_complete416_acceptance'],417,'complete actual416 before417');exact(audit['no_automatic419'],True,'future STOP noautomatic419')
    findings=[f for key in fields for f in previous[key]];exact([f['id'] for f in findings],FINDING_IDS,'all13 original finding identities')
    counts={k:sum(f['classification']==k for f in findings) for k in ['explicit-guarantee-change','underspecified-condition','unproved-native-hypothesis']}
    exact(audit['classification_counts'],counts,'classifications unchanged from WHOLE findings');exact(counts,policy['expected_classification_counts'],'three changes six conditions four hypotheses')
    exact(len(audit['integrated_finding_reviews']),13,'all13 whole finding reviews')
    for row,source in zip(audit['integrated_finding_reviews'],findings):
        exact(row['whole_original_authored_finding'],source,'WHOLE original finding not replaced by repair');exact(row['classification_retained'],source['classification'],'finding class unchanged')
        exact(row['status'],'open-retained-after-integrated-authored-review','open finding not resolved by integration')
        for key in ['independent_impact_acceptance','native_proof','normative_activation','runtime_authority']:exact(row[key],False,'finding remains closed '+key)
    dimensions=audit['all9_joint_dimension_reviews'];exact(len(dimensions),9,'all9 joint dimensions')
    dimension_ids=[x['whole_original397_dimension']['id'] for x in packet['all9_whole_joint_dimension_answers']]
    exact([r['dimension_id'] for r in dimensions],dimension_ids,'exact original dimension order')
    for i,(row,source) in enumerate(zip(dimensions,packet['all9_whole_joint_dimension_answers'])):
        exact(row['whole_original_and_inactive407_answer'],source,'whole original and complete candidate dimension answer');exact(row['whole_remaining407_question'],packet['remaining_actual_joint_reviews'][i],'complete unresolved joint question')
        exact(row['actual_joint_resolution'],None,'actual resolution still unknown');exact(row['all_other_global_dependencies_still_required'],True,'all other dimensions remain required')
    options=audit['all26_whole_option_reviews'];exact(len(options),26,'all26 WHOLE original options')
    option_documents={k:json.loads(inputs[k]) for k in {r['input_key'] for r in original397['option_register']}}
    for i,(row,source) in enumerate(zip(options,original397['option_register'])):
        exact(row['whole_original397_option_register_row'],source,'WHOLE option register including original scope/loss/trust/effect criteria')
        exact(source['whole_option'],option_documents[source['input_key']]['options'][source['source_option_index']],'direct WHOLE original brief option source')
        exact(row['option_register_pointer'],'/option_register/'+str(i),'exact original option index')
        exact(row['selected'],False,'option unselected');exact(row['actual_joint_compatibility'],None,'actual option joint compatibility unknown')
    original_pairs=audit['all325_original_pair_reviews'];candidate_pairs=audit['all36_inactive_candidate_pair_reviews']
    exact(len(original_pairs),325,'all325 original pairs');exact(len(candidate_pairs),36,'all36 inactive candidate pairs')
    exact(packet['whole_original397_all325_pair_questions'],original397['pair_review_questions'],'WHOLE original397 pair baseline unchanged')
    by_ids={tuple(r['option_ids']):r for r in original397['pair_review_questions']}
    for i,(row,source) in enumerate(zip(original_pairs,packet['whole_original397_all325_pair_questions'])):validate_pair_review(row,source,None,options,policy['expected_review_row_sha256']['all325_original_pair_reviews'][i])
    for i,(row,source) in enumerate(zip(candidate_pairs,packet['all36_author_candidate_pair_questions'])):
        original=source['whole_original397_pair_question'];exact(original,by_ids[tuple(original['option_ids'])],'candidate relation belongs to exact original universe')
        validate_pair_review(row,original,source,options,policy['expected_review_row_sha256']['all36_inactive_candidate_pair_reviews'][i])
    exact(len(audit['all8_whole_decision_reviews']),8,'all8 whole conflict decisions')
    for row,source in zip(audit['all8_whole_decision_reviews'],packet['all8_whole_decision_proposals']):
        exact(row['whole_original_and_inactive407_decision'],source,'whole original conflict/options/proposal retained');exact(row['explicit_user_selection'],None,'no decision selected');exact(row['native_conflict_resolved'],False,'no conflict resolved')
    repairs=audit['inactive_repair_dependency_reviews'];exact([r['repair_id'] for r in repairs],REPAIR_IDS,'all four exact inactive clarification impact reviews')
    exact([r['whole_inactive_proposal_and_context'] for r in repairs[:2]],previous['whole_accepted410_clarifications'],'both complete410 original/new wording proposals retained inactive')
    fbyid={f['id']:f for f in findings}
    for row,id_ in zip(repairs[2:],['A411-01','A414-01']):
        exact(row['whole_inactive_proposal_and_context']['whole_original_finding'],fbyid[id_],'whole namespace/membership finding context');exact(row['whole_inactive_proposal_and_context']['complete_inactive_wording_proposal'],fbyid[id_]['inactive_wording_proposal'],'complete unchanged inactive wording')
    for row in repairs:
        exact(row['normative_activation'],False,'repair never activates a clause');exact(row['old_findings_resolved_or_erased'],False,'old findings never erased')
    dependencies=audit['all1286_member_dependency_dispositions'];exact(len(dependencies),1286,'all1286 dependency dispositions')
    position=0
    for i,category in enumerate(previous['all15_category1286_member_impact_reviews']):
        for j,member in enumerate(category['member_reviews']):
            row=dependencies[position];exact(row['category_id'],category['category_id'],'same ordered whole original category');exact(row['whole_415_member_review_reference']['source_path'],sources['inputs']['audit415']['path'],'whole actual415 source path')
            validate_member_dependency(row,previous,'/all15_category1286_member_impact_reviews/'+str(i)+'/member_reviews/'+str(j),repairs,policy['expected_review_row_sha256']['all1286_member_dependency_dispositions'][position]);position+=1
    for row in audit['integrated_finding_reviews']:
        id_=row['finding_id'];exact(row['member_dependency_positions_in_415_local_focus'],[i for i,r in enumerate(dependencies) if id_ in r['open_finding_ids_in_415_local_focus']],'all member impacts for finding,not a sample')
    exact(len(audit['paper_joint_interaction_cases']),6,'all6 paper joint cases')
    for row in audit['paper_joint_interaction_cases']:exact(row['status'],joint_paper_status(row['case'],dimension_ids),'preserve local failure/pending/facts/history without joint proof')
    for field,pins in policy['expected_review_row_sha256'].items():exact([canonical(r) for r in audit[field]],pins,'all complete authored integration rows '+field)
    return True


def review(entry,audit,inputs,source_blobs,sources,policy):
    validate_entry(entry,inputs,policy);validate_sources(inputs,source_blobs,sources,policy);validate_audit(audit,inputs,sources,policy)
    return {'step':416,'state':'prepared-integrated-findings-awaiting-user-acceptance','retained_open_findings':13,'classification_counts':{'explicit-guarantee-change':3,'underspecified-condition':6,'unproved-native-hypothesis':4},'joint_dimensions':9,'whole_options':26,'original_pairs':325,'inactive_candidate_pairs':36,'whole_decisions':8,'member_dependencies':1286,'inactive_repair_reviews':4,'paper_cases':6,'new_findings':0,'runtime_authority':False,'native_cases_run':0,'native_proofs_added':0,'independent_impact_review_accepted':False,'selected_options':None,'approved_contract_migration':None,'current_strong_safe_pause':False,'last_confirmed_strong_safe_pause_step':408,'actual_host_state':'unobserved-not-claimed-absent','actual_live_bindings':None,'actual_global_host_closure':False,'next_preparable_step_after_complete_acceptance':417}
