#!/usr/bin/env python3
"""Supplied whole-member and declaration review; no native oracle or authority."""
import hashlib
import json
import re

POLICY_SHA = 'ff1fe5d9e75278f2515bd9fef6c94c8e7b92d1aa87de3b618b39f2700d377d79'

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
    return exact(canonical(policy), POLICY_SHA, 'authored415 policy substitution')


def validate_sources(inputs, source_blobs, sources, policy):
    validate_policy(policy)
    exact(canonical(sources), policy['fixture_canonical_sha256']['sources'], 'whole authored415 source registry')
    exact(sorted(inputs), sorted(sources['inputs']), 'all133 whole JSON inputs')
    for key, row in sources['inputs'].items():
        exact(sha(inputs[key]), row['sha256'], 'whole source bytes ' + key)
        exact(canonical(json.loads(inputs[key])), row['canonical_sha256'], 'whole source value ' + key)
    previous = json.loads(inputs['sources414'])
    inherited = {k: v for k, v in sources['inputs'].items() if k not in policy['new_source_keys']}
    exact(inherited, previous['inputs'], 'all129 original input bindings unchanged')
    exact(sources['inert_roots'], previous['inert_roots'], 'all four native roots remain inert')
    exact(sources['reviewer_roots'][:-1], previous['reviewer_roots'], 'all prior reviewer roots unchanged')
    roots = sources['inert_roots'] + sources['reviewer_roots'] + [sources['readme']]
    exact(sorted(source_blobs), sorted(row['path'] for row in roots), 'all41 source roots')
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
    exact(sorted(blobs), sorted(baseline), 'all2242 historical414 paths')
    for path, digest in baseline.items():
        raw = blobs[path]
        if path in policy['prefixes']:
            prefix = policy['prefixes'][path].encode()
            if not raw.startswith(prefix):
                raise ValueError('missing exact415 additive prefix')
            raw = raw[len(prefix):]
        exact(sha(raw), digest, 'unchanged historical414 bytes ' + path)
    return True


PAPER_BINDING_KEYS = ['platform','source','version','configuration','boot','attempt','run','authority']


def declared_vector_comparison(case):
    """Compare supplied paper declarations only; this is not a native raw oracle."""
    exact(case['basis'],'authored-hypothetical-declarations-not-native-captures','paper basis only')
    failure=case['original_forward_failed']
    if failure is not None and type(failure) is not bool:
        raise ValueError('strict original failure boolean or null')
    mismatches=[]
    unknown=[]
    def compare(expected,observed,path):
        if expected is None or observed is None:
            unknown.append(path)
        elif type(expected) is not type(observed):
            mismatches.append(path+'/type')
        elif type(expected) is dict:
            for key,value in expected.items():
                if type(key) is not str:raise ValueError('string declaration keys')
                if key not in observed:unknown.append(path+'/'+key)
                else:compare(value,observed[key],path+'/'+key)
            for key in observed:
                if key not in expected:mismatches.append(path+'/'+key+'/unexpected')
        elif type(expected) is list:
            if len(expected)!=len(observed):mismatches.append(path+'/length')
            for i,(a,b) in enumerate(zip(expected,observed)):compare(a,b,path+'/'+str(i))
        elif type(expected) in [str,int,bool]:
            if expected!=observed:mismatches.append(path)
        else:raise ValueError('paper declaration type not a native ABI')
    for side in ['expected_binding','observed_binding']:
        binding=case[side];exact(sorted(binding),sorted(PAPER_BINDING_KEYS),'all own paper binding fields')
        for value in binding.values():
            if value is not None and type(value) is not str:raise ValueError('paper binding label or unknown')
    compare(case['expected_binding'],case['observed_binding'],'/binding')
    compare(case['expected_vector'],case['observed_vector'],'/vector')
    if failure is None:unknown.append('/original_forward_failed')
    return {'known_mismatch_paths':mismatches,'unknown_paths':unknown,
            'supplied_declarations_equal':not mismatches and not unknown,
            'original_forward_failed':failure,'pending_obligations_retained':bool(unknown),
            'original_failure_erased':False,'native_conformance_proven':False,
            'native_raw_artifacts_compared':False,'cross_platform_evidence_transfer_allowed':False,
            'runtime_authority':False,'actual_native_evidence':None}


def validate_entry(entry,inputs,policy):
    validate_policy(policy);exact(canonical(entry),policy['fixture_canonical_sha256']['entry414'],'WHOLE actual414 entry')
    raw=entry['receipt']['text'].encode('utf-8');exact(sha(raw),entry['receipt']['sha256'],'complete414 transcript SHA');exact(len(raw),entry['receipt']['size_bytes'],'complete414 length')
    exact([s for s in entry['receipt']['text'].splitlines() if s.startswith('PASS: ')],policy['receipt_pass_labels'],'all74 ordered414 PASS')
    exact(re.findall(r'^ create mode 100644 (.+)$',entry['receipt']['text'],re.M),policy['receipt_create_paths'],'eight exact414 creates')
    for marker in policy['receipt_single_markers']:exact(entry['receipt']['text'].count(marker),1,'single414 marker')
    exact(entry['receipt']['text'].split(policy['receipt_push_marker'])[1],policy['receipt_final_tail'],'reported main push empty status matching42408bcheads')
    exact(entry['confirmation']['commit_prefix'],'42408bc','accepted414 prefix');exact(entry['confirmation']['commit_full'],None,'full user Git ID unknown');exact(entry['confirmation']['new_strong_safe_pause_confirmed'],False,'414 intermediate checkpoint only')
    exact(entry['whole_confirmed413_entry_reference'],policy['expected_prior_entry_reference'],'WHOLE actual prior413 entry');exact(json.loads(inputs['actual413_entry'])['confirmation']['last_confirmed_strong_safe_pause_step'],408,'last confirmed repository pause408 only')
    return True


def validate_member_review(row,member,category_id,packet,source_documents,expected_sha):
    exact(row['whole_frozen407_member'],member,'WHOLE frozen member including original and complete criteria')
    source=pointer(source_documents[member['source_input_key']],member['source_json_pointer'])
    exact(member['whole_original_member'],source,'direct WHOLE original source dereference')
    exact(canonical(source),member['whole_original_member_canonical_sha256'],'whole original canonical binding')
    criterion=member['complete_candidate_acceptance_criterion']
    exact(row['complete_specific_candidate_evidence_reviewed'],criterion['complete_specific_candidate_evidence'],'whole specific candidate criterion retained')
    exact(row['local_rule_ids_reviewed'],[r['id'] for r in criterion['local_complete_guarantee_positive_negative_expectations']],'ordered complete local positive/negative focus')
    exact(row['local_focus_does_not_waive_any_global_rule_or_other_open_finding'],True,'all global dependencies still due')
    exact(row['unchanged_original_equivalence_established'],False,'no unchanged original equivalence invented')
    exact(row['independently_accepted'],False,'author internal review not independent acceptance')
    exact(row['actual_native_evidence'],None,'no actual member evidence');exact(row['runtime_authority'],False,'no member authority')
    original=member['whole_original_member'];platforms=['Slackware-15.0','Slackware-current']
    if category_id in ['native-cases347','ordered-proof-case-relations']:platforms=[original['platform']]
    exact([b['platform'] for b in row['own_platform_obligations']],platforms,'each OWN required platform,not borrowed support')
    for binding in row['own_platform_obligations']:
        for key in ['actual_source','actual_version','actual_configuration','actual_boot','actual_attempt','actual_run','actual_fresh_explicit_authority','actual_expected_raw_artifacts','actual_observed_raw_artifacts','actual_capture_custody']:exact(binding[key],None,'unknown own-platform '+key)
        exact(binding['native_case_run'],False,'required native case not run');exact(binding['runtime_authority'],False,'no own-platform grant')
    if category_id=='ordered-proof-case-relations':
        sides=row['proof_AND_case_review'];pid=original['qualified_proof_id'];cid=original['case_id'];platform=original['platform']
        exact(sides['qualified_proof_id'],pid,'exact qualified proof side');exact(sides['case_id'],cid,'exact case side');exact(sides['platform'],platform,'own relation platform')
        proof=pointer(packet,sides['whole_proof_member_pointer']);case=pointer(packet,sides['whole_case_member_pointer'])
        exact(proof['member_id'],pid,'whole original proof pointer');exact(case['member_id'],platform+'@'+cid,'whole original own-case pointer')
        exact(sides['complete_proof_specific_criterion'],packet['semantic_register']['proofs'][pid]['complete_specific_candidate_evidence'],'full proof criterion not shortened')
        exact(sides['complete_case_specific_criterion'],packet['semantic_register']['cases'][cid]['complete_specific_candidate_evidence'],'full case criterion not shortened')
        exact(criterion['complete_specific_candidate_evidence'],sides['complete_proof_specific_criterion']+'\nAND this exact case on '+platform+': '+sides['complete_case_specific_criterion'],'original frozen proof AND own-platform case conjunction')
        exact(sides['both_sides_required_on_this_own_platform'],True,'conjunction not disjunction');exact(sides['either_side_sufficient'],False,'neither side alone suffices');exact(sides['native_proof'],False,'no native relation proof');exact(sides['actual_native_evidence'],None,'no actual relation evidence')
    else:exact(row['proof_AND_case_review'],None,'no invented proof-case relation')
    exact(canonical(row),expected_sha,'exact authored specific member assessment and open-finding focus')
    return True


def validate_member_matrix(audit,inputs,policy):
    validate_policy(policy);packet=json.loads(inputs['packet407']);original=packet['all15_category1286_whole_member_acceptance_matrix'];reviewed=audit['all15_category1286_member_impact_reviews']
    exact([c['category_id'] for c in reviewed],[c['category_id'] for c in original],'all15 original ordered categories')
    needed={m['source_input_key'] for c in original for m in c['members']};documents={k:json.loads(inputs[k]) for k in needed}
    total=0
    for i,(category,source) in enumerate(zip(reviewed,original)):
        exact(category['ordered_member_ids'],source['ordered_member_ids'],'all ordered member IDs without sampling/sort/dedup')
        exact(len(category['member_reviews']),len(source['members']),'all full members in category')
        exact(category['authored_all_members_visited'],True,'authored full visit');exact(category['semantic_migration_independently_accepted'],False,'no category independent acceptance')
        for j,(row,member) in enumerate(zip(category['member_reviews'],source['members'])):
            validate_member_review(row,member,category['category_id'],packet,documents,policy['expected_member_review_sha256'][i][j]);total+=1
    exact(total,1286,'all1286 WHOLE member reviews')
    return True


def validate_audit(audit,inputs,sources,policy):
    validate_policy(policy);exact(audit['schema'],1,'integer schema');exact(audit['step'],415,'integer415')
    exact(audit['state'],'prepared-internal-whole-entry-two-platform-member-impact-audit','prepared internal member audit');exact(audit['scope'],'repository-internal-manuscript-audit409-418-only','same finite scope');exact(audit['entry_commit_prefix'],'42408bc','accepted414 entry')
    for key in policy['null_fields']:exact(audit[key],None,'unknown or unselected '+key)
    for key in policy['false_fields']:exact(audit[key],False,'no authority approval completion or pause '+key)
    exact(audit['boundaries'],policy['expected_boundaries'],'complete original closed boundaries');exact(audit['whole_original_requirements_remain_normative'],True,'original norms binding');exact(audit['whole_input_references'],sources['inputs'],'all133 whole input bindings')
    packet=json.loads(inputs['packet407']);previous=json.loads(inputs['audit414']);oracle=json.loads(inputs['entry_oracle406'])
    exact(audit['whole_nine_global_semantic_rules'],packet['semantic_register']['rules'],'all nine complete own-actor global rules')
    for field in ['whole_accepted410_findings','whole_accepted410_clarifications','whole_accepted411_findings','whole_accepted412_findings','whole_accepted413_findings']:exact(audit[field],previous[field],'WHOLE preceding open record '+field)
    exact(audit['whole_accepted414_findings'],previous['new_findings'],'whole414 subject-fact collector-own-effects question')
    exact(audit['new_findings'],[],'no extra defect or closure invented by member mapping')
    exact(audit['interpretation_limit'],policy['expected_interpretation_limit'],'authored map not independent acceptance/native oracle/support/grant')
    exact(audit['remaining_review_and_approval_order'],json.loads(inputs['plan409'])['approval_order'],'independently safe actual review then separate fresh native grant')
    exact(audit['conditional_close_step'],418,'conditional418 target');exact(audit['next_preparable_step_after_complete415_acceptance'],416,'actual415 before416');exact(audit['no_automatic419'],True,'future STOP noautomatic419')
    exact(audit['whole_entry_oracle406_context'],oracle,'WHOLE entry source/oracle/raw/fault requirements,not three-call substitute')
    fields=['all8_source_surface_reconciliations','all6_oracle_role_reconciliations','all6_fault_control_reconciliations','all52_original_case_joint_reconciliations']
    exact(sorted(audit['whole_entry_surface_role_fault_reviews']),sorted(fields),'all entry/surface/role/fault/case review sets')
    for field in fields:
        rows=audit['whole_entry_surface_role_fault_reviews'][field];exact(len(rows),len(oracle[field]),'all own review rows '+field)
        for row,source in zip(rows,oracle[field]):
            exact(row['whole_original406_reconciliation'],source,'WHOLE original406 review row');exact(row['runtime_authority'],False,'no oracle actor exemption or grant');exact(row['actual_native_evidence'],None,'no native oracle observation')
    exact(canonical(audit['whole_entry_surface_role_fault_reviews']),policy['expected_entry_review_sha256'],'exact authored own-entry/role/fault/case assessments')
    validate_member_matrix(audit,inputs,policy)
    exact(audit['paper_raw_declaration_comparisons'],policy['expected_paper_comparisons'],'all18 authored paper comparisons,not raw native expectations')
    for row in audit['paper_raw_declaration_comparisons']:exact(row['comparison'],declared_vector_comparison(row['case']),'typed full supplied-declaration comparison')
    return True


def review(entry,audit,inputs,source_blobs,sources,policy):
    validate_entry(entry,inputs,policy);validate_sources(inputs,source_blobs,sources,policy);validate_audit(audit,inputs,sources,policy)
    return {'step':415,'state':'prepared-member-impact-audit-awaiting-user-acceptance','categories':15,'member_reviews':1286,'qualified_proofs':46,'own_platform_cases':52,'raw_groups':12,'ordered_proof_AND_case_relations':1072,'paper_comparisons':18,'retained_open_findings':13,'new_open_questions':0,'runtime_authority':False,'native_cases_run':0,'native_proofs_added':0,'independent_impact_review_accepted':False,'selected_options':None,'approved_contract_migration':None,'current_strong_safe_pause':False,'last_confirmed_strong_safe_pause_step':408,'actual_host_state':'unobserved-not-claimed-absent','actual_live_bindings':None,'actual_global_host_closure':False,'next_preparable_step_after_complete_acceptance':416}
