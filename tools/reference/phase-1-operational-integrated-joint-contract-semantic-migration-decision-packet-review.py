#!/usr/bin/env python3
"""Review inactive whole-member semantic proposals from supplied data only."""
import hashlib
import json
import re

POLICY_SHA = 'a77594830cf483ed26c422243e55b22c0ebe88ce2e212068bde1b4c48f5d14fb'

def sha(raw):
    return hashlib.sha256(raw).hexdigest()


def canonical(value):
    return sha(json.dumps(value, sort_keys=True, separators=(',', ':'), ensure_ascii=True).encode())


def exact(value, expected, label):
    if type(value) is not type(expected) or (value != expected if type(value) is bytes else canonical(value) != canonical(expected)):
        raise ValueError(label)
    return True


def validate_policy(policy):
    return exact(canonical(policy), POLICY_SHA, 'authored407 policy substitution')


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
    exact(entry['confirmation'], policy['expected_confirmation406'], 'whole accepted406 supplied-return confirmation')
    raw = entry['receipt']['text'].encode('utf-8')
    exact(sha(raw), policy['receipt_sha256'], 'complete disclosed406 transcript SHA')
    exact(len(raw), policy['receipt_size_bytes'], 'complete406 transcript length')
    exact(entry['receipt']['capture_basis'], entry['confirmation']['capture_basis'], 'transcription provenance disclosed')
    exact([s for s in entry['receipt']['text'].splitlines() if s.startswith('PASS: ')], policy['receipt_pass_labels'], 'all102 ordered406 PASS labels')
    exact(re.findall(r'^ create mode 100644 (.+)$', entry['receipt']['text'], re.M), policy['receipt_create_paths'], 'eight406 exact creates')
    for marker in policy['receipt_single_markers']:
        exact(entry['receipt']['text'].count(marker), 1, 'single406 acceptance marker')
    exact(entry['receipt']['text'].split(policy['receipt_push_marker'])[1], policy['receipt_final_tail'], 'reported empty final status and two matching406 heads')
    return True


def validate_sources(inputs, source_blobs, sources, policy):
    validate_policy(policy)
    exact(sorted(inputs), sorted(sources['inputs']), 'all94 whole JSON inputs')
    for key, row in sources['inputs'].items():
        exact(sha(inputs[key]), row['sha256'], 'whole input bytes ' + key)
        exact(canonical(json.loads(inputs[key])), row['canonical_sha256'], 'whole input canonical ' + key)
    previous = json.loads(inputs['sources406'])
    inherited = {k: v for k, v in sources['inputs'].items() if k not in ['entry_oracle406', 'sources406', 'policy406']}
    exact(inherited, previous['inputs'], 'all91 original406 input bindings unchanged')
    exact(sources['previous_readme_binding'], previous['readme'], 'previous accepted README binding retained')
    roots = sources['inert_roots'] + sources['reviewer_roots'] + [sources['readme']]
    exact(sorted(source_blobs), sorted(r['path'] for r in roots), 'all33 pure/inert/accepted406 README roots')
    for row in roots:
        exact(sha(source_blobs[row['path']]), row['sha256'], 'whole root bytes ' + row['path'])
    return True


# This supplied-data derivation is embedded in the delivered pure reviewer.
def derive_changes(parsed):
    candidate=parsed['candidate400'];changes=[]
    host=candidate['exact_adopted_inactive_option_wording'][0]['proposed_clause_text']
    for name in ['/guard_contract/admission','/guard_contract/coverage']:
        changes.append({'id':'T401'+name,'input_key':'original324','json_pointer':name,'whole_current_value':pointer(parsed['original324'],name),'complete_proposed_value':host[name],'source_input':'candidate400','source_pointer':'/exact_adopted_inactive_option_wording/0/proposed_clause_text/'+name.replace('~','~0').replace('/','~1'),'replacement_approved':False})
    for row in parsed['operation402']['exact_inactive_clause_replacements']:
        prefix='F402' if row['json_pointer'].startswith('/forward') or row['json_pointer'].startswith('/fence') else ('R402' if row['json_pointer'].startswith('/recovery') else 'P402')
        changes.append({'id':prefix+row['json_pointer'],'input_key':row['input_key'],'json_pointer':row['json_pointer'],'whole_current_value':row['whole_current_clause'],'complete_proposed_value':row['proposed_complete_clause_text'],'source_input':'operation402','source_pointer':'/exact_inactive_clause_replacements/'+str(parsed['operation402']['exact_inactive_clause_replacements'].index(row)),'replacement_approved':False})
    row=parsed['loss403']['exact_clock_clause_proposal']
    changes.append({'id':'C403'+row['json_pointer'],'input_key':row['input_key'],'json_pointer':row['json_pointer'],'whole_current_value':row['whole_current_clause'],'complete_proposed_value':row['proposed_complete_clause_text'],'source_input':'loss403','source_pointer':'/exact_clock_clause_proposal','replacement_approved':False})
    for n,row in enumerate(parsed['publication405']['exact_inactive_clause_replacements']):
        changes.append({'id':'E405'+row['json_pointer'],'input_key':row['input_key'],'json_pointer':row['json_pointer'],'whole_current_value':row['whole_current_value'],'complete_proposed_value':row['whole_proposed_value'],'source_input':'publication405','source_pointer':'/exact_inactive_clause_replacements/'+str(n),'replacement_approved':False})
    for row in changes:exact(row['whole_current_value'],pointer(parsed[row['input_key']],row['json_pointer']),'exact original amendment clause independently bound')
    return changes

def scope_spec(ids,text):
    return {'local_focus_rule_ids':ids.split(),'complete_specific_candidate_evidence':text}

def derive_semantics(parsed,definitions):
    semantics={'rules':definitions['rules'],'proofs':{k:scope_spec(*v) for k,v in definitions['proofs'].items()},'cases':{k:scope_spec(*v) for k,v in definitions['cases'].items()},'other_members':{},'entry_before_effects':definitions['entry_before_effects']}
    for c in parsed['oracle_brief396']['impact_categories']:
        cid=c['id'];values=c['whole_current_value'];members={}
        for n,mid in enumerate(c['ordered_member_ids']):
            value=values[mid] if type(values) is dict else values[n]
            if cid in ['qualified-proofs347','native-cases347','ordered-proof-case-relations']:continue
            label=mid;custom=None
            if cid=='contracts320-327':ids=definitions['contracts'][mid]
            elif cid=='normative-sections347':ids=definitions['sections'][mid]
            elif cid=='gaps348':label=value['inherited_gap']['id'];ids=definitions['gaps'][label]
            elif cid=='prerequisites365':label=value['id'];ids=definitions['gaps'][label]
            elif cid=='raw-groups335':ids=definitions['raw'][mid]
            elif cid=='test-entry377':ids,custom=definitions['entry'][mid]
            elif cid=='operational-readiness377':ids,custom=definitions['readiness'][mid]
            elif cid=='historical-five-families':ids=definitions['all'];label=value['family']
            elif cid=='supplemental-input365':ids=definitions['all'];label=value['name_candidate']
            elif cid=='feasibility-blockers372':label=value['family_id'];ids=definitions['blockers'][label]
            elif cid=='whole-conflicts389':ids=definitions['conflicts'][mid]
            elif cid=='native-cut-dimensions376':ids=definitions['cuts'][mid]
            else:raise ValueError('unclassified original impact category')
            # Full original value remains a retained comparison baseline in the member row.
            # Local rules are focus only;all global semantic boundaries apply to EVERY dependent own effect.
            text=custom if custom is not None else definitions['purposes'][cid]
            members[mid]=dict(scope_spec(ids,text),whole_member_label=label)
        if members:semantics['other_members'][cid]=members
    return semantics

def member_candidate_criterion(category,mid,original,semantics):
    if category=='qualified-proofs347':spec=semantics['proofs'][original['qualified_id']]
    elif category=='native-cases347':spec=semantics['cases'][original['case_id']]
    elif category=='ordered-proof-case-relations':
        proof=semantics['proofs'][original['qualified_proof_id']];case=semantics['cases'][original['case_id']]
        ids=[k for k in sorted(semantics['rules']) if k in proof['local_focus_rule_ids'] or k in case['local_focus_rule_ids']]
        spec={'local_focus_rule_ids':ids,'complete_specific_candidate_evidence':proof['complete_specific_candidate_evidence']+'\nAND this exact case on '+original['platform']+': '+case['complete_specific_candidate_evidence']}
    else:spec=semantics['other_members'][category][mid]
    rules=[dict(semantics['rules'][rid],id=rid) for rid in spec['local_focus_rule_ids']]
    return {'complete_specific_candidate_evidence':spec['complete_specific_candidate_evidence'],'whole_original_member_is_comparison_baseline_not_unchanged_claim_for_amended_guarantees':True,'global_rule_register_pointer':'/semantic_register/rules','all_global_rules_apply_to_complete_dependency_and_own_actor_scope':True,'local_focus_does_not_waive_other_global_rules':True,'local_complete_guarantee_positive_negative_expectations':rules,'proposed_scope_not_current_original_equivalence':True,'actual_native_evidence':None,'independently_accepted':False,'native_proof':False,'runtime_authority':False}

def derive_matrix(parsed,semantics):
    matrix=[]
    for c in parsed['oracle_brief396']['impact_categories']:
        values=c['whole_current_value'];rows=[]
        for n,mid in enumerate(c['ordered_member_ids']):
            original=values[mid] if type(values) is dict else values[n]
            suffix='/'+mid.replace('~','~0').replace('/','~1') if type(values) is dict else '/'+str(n)
            rows.append({'member_id':mid,'position':n,'source_input_key':c['input_key'],'source_path':c['path'],'source_json_pointer':c['json_pointer']+suffix,'whole_original_member':original,'whole_original_member_canonical_sha256':canonical(original),'complete_candidate_acceptance_criterion':member_candidate_criterion(c['id'],mid,original,semantics),'current_original_normative':True,'independent_migration_approval':None,'actual_native_status_promoted':False})
        matrix.append({'category_id':c['id'],'whole_original_category_binding':{k:v for k,v in c.items() if k!='whole_current_value'},'ordered_member_ids':c['ordered_member_ids'],'members':rows,'authored_member_coverage_complete':True,'semantic_migration_independently_accepted':False})
    return matrix

def derive_contract_views(parsed,changes,semantics):
    views=[]
    for step in range(320,328):
        key='original'+str(step);original=parsed[key];draft=json.loads(json.dumps(original));used=[]
        for row in changes:
            if row['input_key']!=key:continue
            parts=[p.replace('~1','/').replace('~0','~') for p in row['json_pointer'].split('/')[1:]];target=draft
            for p in parts[:-1]:target=target[int(p)] if type(target) is list else target[p]
            last=int(parts[-1]) if type(target) is list else parts[-1];target[last]=row['complete_proposed_value'];used.append(row['id'])
        views.append({'step':step,'source_input_key':key,'whole_current_document':original,'inactive_exact_clause_patch_view':draft,'exact_replacement_ids_applied':used,'complete_candidate_acceptance_criterion':member_candidate_criterion('contracts320-327',str(step),original,semantics),'patch_view_is_complete_native_protocol':False,'embedded_original_proof_or_case_text_requires_member_matrix_semantic_interpretation':True,'current_original_document_remains_normative':True,'approved_or_activated':False})
    return views

def prepare_parsed(inputs):
    initial=['candidate400','packet397','oracle_brief396','trust401','operation402','loss403','storage404','publication405','publication_requirements316']+['original'+str(n) for n in range(320,328)]
    parsed={k:json.loads(inputs[k]) for k in initial}
    for c in parsed['oracle_brief396']['impact_categories']:
        if c['input_key'] not in parsed:parsed[c['input_key']]=json.loads(inputs[c['input_key']])
    return parsed

def derive_loss_register(parsed):
    candidate=parsed['candidate400']
    return {'whole400_all9_source_guarantee_loss_register':candidate['complete_source_guarantee_loss_register'],'whole402_additional_forward_recovery_publication_losses':parsed['operation402']['additional_joint_guarantee_losses'],'whole400_known_current_normative_incompatibilities':candidate['known_draft_incompatibilities'],'whole401_shared_writer_clock_losses':parsed['trust401']['complete400_writer_clock_guarantee_losses'],'whole405_394_stage_terminal_changed_guarantees':parsed['publication405']['whole394_selected_for_drafting_option']['guarantees_lost_or_changed']}

def derive_decisions(parsed,semantics):
    candidate=parsed['candidate400'];rows=[]
    for row in parsed['packet397']['decision_rows']:
        refs=[r for r in candidate['draft_option_references'] if r['input_key'] in row['source_family_input_keys']]
        rules=semantics['other_members']['whole-conflicts389'][row['id']]['local_focus_rule_ids']
        rows.append({'whole_original397_decision':row,'author_proposed_option_references':refs,'complete_candidate_guarantee_positive_negative_expectations':[dict(semantics['rules'][k],id=k) for k in rules],'explicit_user_selection':None,'independent_joint_specification_acceptance':None,'independent_impact_acceptance':None,'explicit_migration_approval':None,'actual_implementation_selection':None,'fresh_native_test_grant':None,'native_conflict_resolved':False,'runtime_authority':False})
    return rows

def derive_dimensions(parsed,policy):
    return [{'whole_original397_dimension':r,'complete_inactive_candidate_joint_answer':policy['dimension_answers'][r['id']],'actual_joint_source_component_or_effect_binding':None,'independent_joint_answer_accepted':False,'native_compatibility_proven':False,'runtime_authority':False} for r in parsed['packet397']['joint_review_dimensions']]

def validate_matrix(actual,parsed,semantics):
    categories=parsed['oracle_brief396']['impact_categories']
    exact([c['category_id'] for c in actual],[c['id'] for c in categories],'ALL15 categories exact order')
    for row,c in zip(actual,categories):
        exact(row['whole_original_category_binding'],{k:v for k,v in c.items() if k!='whole_current_value'},'whole original category source binding')
        exact(row['ordered_member_ids'],c['ordered_member_ids'],'ALL whole ordered member identities')
        exact([r['member_id'] for r in row['members']],c['ordered_member_ids'],'ALL1286 individual ordered members')
        exact(row['authored_member_coverage_complete'],True,'authored coverage');exact(row['semantic_migration_independently_accepted'],False,'author is not independent acceptance')
        for n,(member,mid) in enumerate(zip(row['members'],c['ordered_member_ids'])):
            values=c['whole_current_value'];original=values[mid] if type(values) is dict else values[n]
            suffix='/'+mid.replace('~','~0').replace('/','~1') if type(values) is dict else '/'+str(n)
            ptr=c['json_pointer']+suffix
            exact(member['position'],n,'exact member order');exact(member['source_input_key'],c['input_key'],'exact whole member source');exact(member['source_path'],c['path'],'exact source path');exact(member['source_json_pointer'],ptr,'exact source pointer')
            exact(member['whole_original_member'],original,'WHOLE original member statement');exact(member['whole_original_member'],pointer(parsed[c['input_key']],ptr),'direct independent whole source object');exact(member['whole_original_member_canonical_sha256'],canonical(original),'whole source member SHA')
            exact(member['complete_candidate_acceptance_criterion'],member_candidate_criterion(c['id'],mid,original,semantics),'complete specific candidate guarantee/positive/negative criterion')
            exact(member['current_original_normative'],True,'original current norm');exact(member['independent_migration_approval'],None,'no migration approval');exact(member['actual_native_status_promoted'],False,'no native promotion')
    return True

def validate_review_shape(review,inputs,sources,policy):
    validate_policy(policy);exact(review['schema'],1,'integer schema');exact(review['step'],407,'integer407');exact(review['state'],'inactive-integrated-joint-semantic-migration-decision-packet','inactive packet')
    for key in policy['null_fields']:exact(review[key],None,'no actual selection/approval/native '+key)
    for key in policy['false_fields']:exact(review[key],False,'no unsafe equivalence/approval/authority '+key)
    for key in ['authored_member_coverage_complete','authored_semantic_proposal_complete_for_review','whole_original_requirements_remain_normative']:exact(review[key],True,'complete authored reviewable scope,current norm')
    for key in ['native_cases_run','native_proofs_added']:exact(review[key],0,'zero native progress')
    exact(review['actual_host_state'],'unobserved-not-claimed-absent','no actual host inference')
    parsed=prepare_parsed(inputs);candidate=parsed['candidate400'];packet=parsed['packet397']
    exact(review['scope'],candidate['scope'],'finite399-408scope');exact(review['candidate_id'],'JCP400-A','same author recommendation');exact(review['boundaries'],candidate['boundaries'],'all original closed boundaries')
    for key,source in policy['reference_fields'].items():exact(review[key],sources['inputs'][source],'whole byte-bound source '+source)
    for key,name in [('whole400_candidate_option_references','draft_option_references'),('whole400_four_initial_amendment_wordings','exact_adopted_inactive_option_wording'),('whole400_six_joint_wordings','new_joint_wording'),('whole400_retention_comparator','retention_comparator'),('whole400_deferral_comparator','deferral_comparator')]:exact(review[key],candidate[name],'whole original author options/wording/comparators')
    exact(canonical(policy['semantic_definitions']),policy['semantic_definition_sha256'],'pinned authored semantic definitions')
    semantics=derive_semantics(parsed,policy['semantic_definitions']);exact(review['semantic_register'],semantics,'complete specific proof/case/member evidence register and nine global rules')
    exact(review['complete_guarantee_loss_and_incompatibility_register'],derive_loss_register(parsed),'all original and additional forward/recovery/publication losses')
    changes=derive_changes(parsed);exact(review['exact14_inactive_clause_replacements'],changes,'ALL14 whole current/proposed source-bound exact replacements')
    adopted=candidate['exact_adopted_inactive_option_wording']
    assumptions={'trusted_host_assumption':adopted[0]['proposed_clause_text']['trusted_host_assumption'],'local_clock_trust_assumption':adopted[2]['proposed_clause_text']['local_clock_trust_assumption'],'external_finalization_obligation':adopted[3]['proposed_clause_text']['external_finalization_obligation'],'terminal_acceptance_cut':adopted[3]['proposed_clause_text']['terminal_acceptance_cut']}
    exact(review['complete4_additional_trust_and_terminal_assumptions'],assumptions,'WHOLE host/clock/external-finalization/terminal assumptions')
    exact(review['whole8_current_and_inactive_patch_contract_views'],derive_contract_views(parsed,changes,semantics),'ALL8 complete current contracts plus exact inactive patch/semantic views')
    validate_matrix(review['all15_category1286_whole_member_acceptance_matrix'],parsed,semantics)
    exact(review['all8_whole_decision_proposals'],derive_decisions(parsed,semantics),'WHOLE8 decision alternatives,separate unanswered approval questions')
    exact(review['all9_whole_joint_dimension_answers'],derive_dimensions(parsed,policy),'WHOLE9 specific joint answers,actual/native unknown')
    exact(review['whole_original397_all325_pair_questions'],packet['pair_review_questions'],'ALL325 original pair questions')
    exact(review['all36_author_candidate_pair_questions'],policy['expected_joint_pairs'],'ALL36 candidate pair whole questions and combined obligations')
    exact(review['remaining_actual_joint_reviews'],candidate['nine_unresolved_joint_reviews'],'all9 actual joint questions still unresolved')
    exact(review['next_preparable_step_after_complete407_acceptance'],408,'408after FULL407actualacceptance');exact(review['conditional_close_step'],408,'same finite block close');exact(review['no_automatic409'],True,'STOPafter confirmed408')
    return True

def validate_fixtures(fixtures, policy):
    validate_policy(policy)
    exact(sorted(fixtures), sorted(policy['fixture_canonical_sha256']), 'exact407 fixture set')
    for name, value in fixtures.items():
        exact(canonical(value), policy['fixture_canonical_sha256'][name], 'whole authored407 fixture ' + name)
    return True


def validate_repository(blobs, baseline, policy):
    validate_policy(policy)
    exact(sorted(blobs), sorted(baseline), 'all2178 historical406 paths')
    for path, digest in baseline.items():
        raw = blobs[path]
        if path in policy['prefixes']:
            addition = policy['prefixes'][path].encode()
            if not raw.startswith(addition):
                raise ValueError('missing exact407 additive prefix')
            raw = raw[len(addition):]
        exact(sha(raw), digest, 'all historical406 bytes unchanged ' + path)
    return True


def review(entry,proposal,inputs,source_blobs,sources,policy):
    validate_entry(entry,policy);validate_sources(inputs,source_blobs,sources,policy);validate_review_shape(proposal,inputs,sources,policy)
    return {'step': 407, 'state': 'prepared-inactive-integrated-semantic-decision-packet-user-acceptance-pending', 'selected_options': None, 'approved_contract_migration': None, 'independent_impact_review_accepted': False, 'semantic_migration_complete': False, 'runtime_authority': False, 'last_confirmed_repository_pause': 398, 'strong_safe_pause': False, 'after_complete407_acceptance_next_preparable_step': 408, 'conditional_close_step': 408, 'after_confirmed408_next_authorized_stage': None}
