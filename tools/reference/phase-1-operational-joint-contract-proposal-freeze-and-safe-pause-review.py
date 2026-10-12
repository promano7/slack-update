#!/usr/bin/env python3
"""Review a frozen inactive manuscript and conditional repository pause from supplied data."""
import hashlib
import json
import re

POLICY_SHA = '3112e031ac7a91cc42932a635d6d14efcda3d9c4439c2b045de036d16d4faf18'

def sha(raw):
    return hashlib.sha256(raw).hexdigest()


def canonical(value):
    return sha(json.dumps(value, sort_keys=True, separators=(',', ':'), ensure_ascii=True).encode())


def exact(value, expected, label):
    if type(value) is not type(expected) or (value != expected if type(value) is bytes else canonical(value) != canonical(expected)):
        raise ValueError(label)
    return True


def validate_policy(policy):
    return exact(canonical(policy), POLICY_SHA, 'authored408 policy substitution')


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
    exact(entry['confirmation'], policy['expected_confirmation407'], 'whole accepted407 supplied-return confirmation')
    raw = entry['receipt']['text'].encode('utf-8')
    exact(sha(raw), policy['receipt_sha256'], 'complete disclosed407 transcript SHA')
    exact(len(raw), policy['receipt_size_bytes'], 'complete407 transcript length')
    exact(entry['receipt']['capture_basis'], entry['confirmation']['capture_basis'], 'transcription provenance disclosed')
    exact([s for s in entry['receipt']['text'].splitlines() if s.startswith('PASS: ')], policy['receipt_pass_labels'], 'all88 ordered407 PASS labels')
    exact(re.findall(r'^ create mode 100644 (.+)$', entry['receipt']['text'], re.M), policy['receipt_create_paths'], 'eight407 exact creates')
    for marker in policy['receipt_single_markers']:
        exact(entry['receipt']['text'].count(marker), 1, 'single407 acceptance marker')
    exact(entry['receipt']['text'].split(policy['receipt_push_marker'])[1], policy['receipt_final_tail'], 'reported empty final status and two matching407 heads')
    return True


def validate_sources(inputs, source_blobs, sources, policy):
    validate_policy(policy)
    exact(sorted(inputs), sorted(sources['inputs']), 'all106 whole JSON inputs')
    for key, row in sources['inputs'].items():
        exact(sha(inputs[key]), row['sha256'], 'whole input bytes ' + key)
        exact(canonical(json.loads(inputs[key])), row['canonical_sha256'], 'whole input canonical ' + key)
    previous = json.loads(inputs['sources407'])
    inherited = {k: v for k, v in sources['inputs'].items() if k not in policy['new_source_input_keys']}
    exact(inherited, previous['inputs'], 'all94 original407 input bindings unchanged')
    exact(sources['previous_readme_binding'], previous['readme'], 'previous accepted README binding retained')
    roots = sources['inert_roots'] + sources['reviewer_roots'] + [sources['readme']]
    exact(sorted(source_blobs), sorted(r['path'] for r in roots), 'all34 pure/inert/accepted407 README roots')
    for row in roots:
        exact(sha(source_blobs[row['path']]), row['sha256'], 'whole root bytes ' + row['path'])
    return True


def validate_one_supplied_checkpoint(actual,expected_policy,step):
    exact(actual['confirmation'],expected_policy['expected_confirmation'+str(step)],'WHOLE actual accepted checkpoint confirmation')
    raw=actual['receipt']['text'].encode('utf-8')
    exact(actual['receipt']['schema'],1,'integer receipt schema');exact(actual['receipt']['step'],step,'same original receipt step')
    exact(sha(raw),expected_policy['receipt_sha256'],'complete actual receipt bytes');exact(len(raw),expected_policy['receipt_size_bytes'],'complete original receipt size')
    exact(actual['receipt']['sha256'],sha(raw),'receipt hash');exact(actual['receipt']['size_bytes'],len(raw),'receipt size');exact(actual['receipt']['capture_basis'],actual['confirmation']['capture_basis'],'whole original receipt provenance')
    exact([s for s in actual['receipt']['text'].splitlines() if s.startswith('PASS: ')],expected_policy['receipt_pass_labels'],'ALL original ordered pass labels')
    exact(re.findall(r'^ create mode 100644 (.+)$',actual['receipt']['text'],re.M),expected_policy['receipt_create_paths'],'ALL original exact created paths')
    for marker in expected_policy['receipt_single_markers']:exact(actual['receipt']['text'].count(marker),1,'single actual checkpoint marker')
    exact(actual['receipt']['text'].split(expected_policy['receipt_push_marker'])[1],expected_policy['receipt_final_tail'],'successful supplied push/empty status/matching heads')
    return True

def validate_checkpoint_chain(chain,entry,inputs,sources,policy):
    exact([r['step'] for r in chain],list(range(399,408)),'ALL9 actual checkpoint steps in exact order')
    for row in chain:
        n=row['step'];actual=json.loads(inputs['actual'+str(n)+'_entry']) if n<407 else entry
        expected_policy=json.loads(inputs['policy'+str(n+1)]) if n<407 else policy
        reference=sources['inputs']['actual'+str(n)+'_entry'] if n<407 else policy['current_entry_reference']
        exact(row['whole_actual_entry'],actual,'WHOLE original supplied checkpoint entry');exact(row['entry_reference'],reference,'whole actual entry source binding')
        validate_one_supplied_checkpoint(actual,expected_policy,n)
        exact(row['full_Git_ID_known'],False,'no fabricated full Git ID');exact(actual['confirmation']['commit_full'],None,'full original Git ID unknown')
        exact(row['repository_checkpoint_is_new_strong_pause'],False,'no intermediate pause invented')
    return True

def validate_whole_packet407(packet,inputs,sources):
    original=json.loads(inputs['packet407']);exact(packet,original,'WHOLE accepted407 packet,not shortened counts/hash-only references')
    exact(packet['step'],407,'integer407');exact(packet['state'],'inactive-integrated-joint-semantic-migration-decision-packet','inactive original packet')
    exact(packet['whole_original_requirements_remain_normative'],True,'original current norms')
    for key in ['selected_options','approved_joint_specification','approved_contract_migration','actual_selected_implementation','actual_joint_native_graph','actual_native_evidence','actual_two_platform_run_bindings','actual_live_bindings']:exact(packet[key],None,'no selected/approved/actual/native '+key)
    for key in ['independent_impact_review_accepted','semantic_migration_complete','runtime_authority','actual_global_host_closure','current_strong_safe_pause']:exact(packet[key],False,'no native/approval/current pause '+key)
    for key in ['native_cases_run','native_proofs_added']:exact(packet[key],0,'zero native progress')
    oracle=json.loads(inputs['oracle_brief396']);categories=oracle['impact_categories'];matrix=packet['all15_category1286_whole_member_acceptance_matrix']
    exact([c['category_id'] for c in matrix],[c['id'] for c in categories],'ALL15 whole original categories')
    parsed={}
    for actual,category in zip(matrix,categories):
        exact(actual['ordered_member_ids'],category['ordered_member_ids'],'WHOLE ordered member identities');exact([r['member_id'] for r in actual['members']],category['ordered_member_ids'],'ALL1286 full members,not samples')
        key=category['input_key']
        if key not in parsed:parsed[key]=json.loads(inputs[key])
        for row in actual['members']:
            exact(row['whole_original_member'],pointer(parsed[key],row['source_json_pointer']),'direct WHOLE original source member')
            criterion=row['complete_candidate_acceptance_criterion']
            exact(criterion['actual_native_evidence'],None,'no native evidence');exact(criterion['native_proof'],False,'no paper proof');exact(criterion['runtime_authority'],False,'no member native right');exact(criterion['independently_accepted'],False,'author not independent approval')
    return True

def validate_review_shape(freeze,entry,inputs,sources,policy):
    validate_policy(policy);exact(freeze['schema'],1,'integer schema');exact(freeze['step'],408,'integer408');exact(freeze['state'],'frozen-inactive-joint-proposal-prepared-final-user-acceptance-pending','PREPARED final acceptance pending')
    for key in policy['null_fields']:exact(freeze[key],None,'no current408 confirmation/commit/actual/approval '+key)
    for key in policy['false_fields']:exact(freeze[key],False,'no native/selfconfirmation/closure '+key)
    for key in policy['true_fields']:exact(freeze[key],True,'whole scope and only conditional eligibility '+key)
    for key in ['native_cases_run','native_proofs_added']:exact(freeze[key],0,'zero native progress')
    exact(freeze['actual_host_state'],'unobserved-not-claimed-absent','host never assumed absent')
    exact(freeze['last_confirmed_strong_safe_pause_step'],398,'last confirmed398only')
    candidate=json.loads(inputs['candidate400']);history=json.loads(inputs['freeze398'])
    exact(freeze['scope'],candidate['scope'],'final399-408scope');exact(freeze['candidate_id'],'JCP400-A','same inactive author draft');exact(freeze['boundaries'],candidate['boundaries'],'all original closed boundaries')
    exact(freeze['frozen_inputs'],sources['inputs'],'ALL106 whole input bindings');exact(freeze['frozen_source_roots'],sources['inert_roots']+sources['reviewer_roots']+[sources['readme']],'ALL34 whole pure/inert/accepted407 README roots')
    exact(freeze['whole_original_prepared398_reference'],sources['inputs']['freeze398'],'whole original prepared398 source')
    exact(freeze['whole_399_roadmap'],json.loads(inputs['plan399'])['roadmap'],'WHOLE finite399-408roadmap');exact(freeze['whole_399_pause_policy'],json.loads(inputs['plan399'])['pause_policy'],'WHOLE original pause policy')
    historical=json.loads(inputs['historical_actual398_entry']);exact(freeze['whole_historical398_external_entry'],historical,'WHOLE original actual398 external entry/receipt/conditions')
    exact(historical['confirmation']['scope'],'repository-contract-decision-proposals389-398-only','historical scope never expanded');exact(historical['confirmation']['strong_safe_pause'],True,'historical398 externally accepted')
    exact([r['whole_prepared398_condition'] for r in historical['external_conditions']['conditions']],history['conditions'],'ALL9 WHOLE historical prepared398 conditions externally retained')
    exact([r['whole_original_prepared398_condition'] for r in freeze['conditions']],history['conditions'],'ALL9 WHOLE original conditions with complete nested history')
    exact(freeze['conditions'],policy['expected_conditions'],'ALL9 exact current-scope wrappers/review bases/current408confirmationpending')
    exact(freeze['after_final_acceptance'],policy['expected_after_final_acceptance'],'external final actual ALL-nine review then STOP/noautomatic409/newrequest')
    exact(freeze['required_final_commit_message'],policy['required_final_commit_message'],'exact final scoped commit message')
    exact(freeze['final_receipt_rule'],policy['expected_final_receipt_rule'],'whole final receipt and external confirmation rule')
    validate_checkpoint_chain(freeze['accepted_checkpoint_chain399_407'],entry,inputs,sources,policy)
    validate_whole_packet407(freeze['whole_accepted407_packet'],inputs,sources)
    for row in sources['inert_roots']:
        exact(row['execution_authorized'],False,'inert native root never authorized');exact(row['actual_native_binding'],None,'native root unbound')
    exact(freeze['next_authorized_stage_after408'],None,'STOPnoautomatic409');exact(freeze['no_automatic409'],True,'new request required after confirmed408')
    return True

def validate_fixtures(fixtures, policy):
    validate_policy(policy)
    exact(sorted(fixtures), sorted(policy['fixture_canonical_sha256']), 'exact408 fixture set')
    for name, value in fixtures.items():
        exact(canonical(value), policy['fixture_canonical_sha256'][name], 'whole authored408 fixture ' + name)
    return True


def validate_repository(blobs, baseline, policy):
    validate_policy(policy)
    exact(sorted(blobs), sorted(baseline), 'all2186 historical407 paths')
    for path, digest in baseline.items():
        raw = blobs[path]
        if path in policy['prefixes']:
            addition = policy['prefixes'][path].encode()
            if not raw.startswith(addition):
                raise ValueError('missing exact408 additive prefix')
            raw = raw[len(addition):]
        exact(sha(raw), digest, 'all historical407 bytes unchanged ' + path)
    return True


def review(entry,proposal,inputs,source_blobs,sources,policy):
    validate_entry(entry,policy);validate_sources(inputs,source_blobs,sources,policy);validate_review_shape(proposal,entry,inputs,sources,policy)
    return {'step': 408, 'state': 'frozen-inactive-proposal-prepared-final-user-acceptance-external-pause-pending', 'repository_review_eligible_for_conditional_pause': True, 'actual_strong_safe_pause_confirmed': False, 'selected_options': None, 'approved_contract_migration': None, 'runtime_authority': False, 'native_cases_run': 0, 'native_proofs_added': 0, 'last_confirmed_strong_safe_pause_step': 398, 'actual_host_state': 'unobserved-not-claimed-absent', 'actual_live_bindings': None, 'actual_global_host_closure': False, 'current408_actual_final_user_receipt': None, 'after_confirmed408_next_authorized_stage': None, 'no_automatic409': True}
