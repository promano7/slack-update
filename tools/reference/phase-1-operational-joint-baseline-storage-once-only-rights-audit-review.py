#!/usr/bin/env python3
"""Supplied storage status/branch review; never a native recovery selector."""
import hashlib
import json
import re

POLICY_SHA = 'dc63d3bf92d871531e71b0969cdc20ad944299b08d8f3bd8d298e5bfefb21aaf'

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
    return exact(canonical(policy), POLICY_SHA, 'authored409 policy substitution')


def validate_sources(inputs, source_blobs, sources, policy):
    validate_policy(policy)
    exact(canonical(sources), policy['fixture_canonical_sha256']['sources'], 'whole authored413 source registry')
    exact(sorted(inputs), sorted(sources['inputs']), 'all125 whole JSON inputs')
    for key, row in sources['inputs'].items():
        exact(sha(inputs[key]), row['sha256'], 'whole source bytes ' + key)
        exact(canonical(json.loads(inputs[key])), row['canonical_sha256'], 'whole source value ' + key)
    previous = json.loads(inputs['sources412'])
    inherited = {k: v for k, v in sources['inputs'].items() if k not in policy['new_source_keys']}
    exact(inherited, previous['inputs'], 'all121 original input bindings unchanged')
    exact(sources['inert_roots'], previous['inert_roots'], 'all four native roots remain inert')
    exact(sources['reviewer_roots'][:-1], previous['reviewer_roots'], 'all prior reviewer roots unchanged')
    roots = sources['inert_roots'] + sources['reviewer_roots'] + [sources['readme']]
    exact(sorted(source_blobs), sorted(row['path'] for row in roots), 'all39 source roots')
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
    exact(sorted(blobs), sorted(baseline), 'all2226 historical412 paths')
    for path, digest in baseline.items():
        raw = blobs[path]
        if path in policy['prefixes']:
            prefix = policy['prefixes'][path].encode()
            if not raw.startswith(prefix):
                raise ValueError('missing exact413 additive prefix')
            raw = raw[len(prefix):]
        exact(sha(raw), digest, 'unchanged historical412 bytes ' + path)
    return True


"""Preserve hypothetical storage/action status components; never select recovery."""
STATUS_CHOICES={
 'qualified_captured_target_fact':[None,'qualified-original-match-at-capture-cut','qualified-original-mismatch-at-capture-cut'],
 'backup_binding':['known-exact','known-absent','unknown'],
 'claim_outcome':['known-consumed','unknown'],
 'launch_outcome':['known-spent','unknown'],
 'restore_outcome':['known-applied','known-not-performed','unknown'],
 'owned_commit_outcome':['known-durable','known-partial','unknown'],
 'controller_outcome':['known','unknown'],
 'original_action_spend':['known-spent','known-unused','unknown'],
 'original_verification_right':['known-original-valid','known-exhausted','unknown']}


def status_vector(case):
    exact(case['hypothetical_only'],True,'hypothetical storage input only')
    fields={}
    for key,allowed in STATUS_CHOICES.items():
        if case[key] not in allowed:raise ValueError('invalid original status component '+key)
        fields[key]=case[key]
    for key in ['original_forward_failed','original_mismatch']:
        if case[key] is not None and type(case[key]) is not bool:raise ValueError('original failure/status type')
        fields[key]=case[key]
    return {'separate_original_status_components':fields,
            'pending_component_names':[key for key,value in fields.items() if value is None or value=='unknown'],
            'restore_selected':False,'verification_selected':False,'commit_selected':False,
            'unknown_action_may_repeat':False,'claim_or_launch_may_reopen':False,
            'spend_may_refund':False,'target_fact_completes_unknown_ACK':False,
            'qualified_fact_proves_current_invariance':False,
            'runtime_authority':False,'native_evidence':None,'actual_global_host_closure':False}


def validate_entry(entry,inputs,policy):
    validate_policy(policy);exact(canonical(entry),policy['fixture_canonical_sha256']['entry412'],'WHOLE actual412 entry')
    raw=entry['receipt']['text'].encode('utf-8');exact(sha(raw),entry['receipt']['sha256'],'complete412 transcript SHA');exact(len(raw),entry['receipt']['size_bytes'],'complete412 length')
    exact([s for s in entry['receipt']['text'].splitlines() if s.startswith('PASS: ')],policy['receipt_pass_labels'],'all69 ordered412 PASS')
    exact(re.findall(r'^ create mode 100644 (.+)$',entry['receipt']['text'],re.M),policy['receipt_create_paths'],'eight exact412 creates')
    for marker in policy['receipt_single_markers']:exact(entry['receipt']['text'].count(marker),1,'single412 marker')
    exact(entry['receipt']['text'].split(policy['receipt_push_marker'])[1],policy['receipt_final_tail'],'reported main push empty status matching12bd22aheads')
    exact(entry['confirmation']['commit_prefix'],'12bd22a','accepted412 prefix');exact(entry['confirmation']['commit_full'],None,'full user Git ID unknown')
    exact(entry['confirmation']['new_strong_safe_pause_confirmed'],False,'412 intermediate checkpoint only')
    exact(entry['whole_confirmed411_entry_reference'],policy['expected_prior_entry_reference'],'WHOLE prior411 actual entry')
    exact(json.loads(inputs['actual411_entry'])['confirmation']['last_confirmed_strong_safe_pause_step'],408,'last confirmed repository pause408 only')
    return True


def validate_audit(audit,inputs,sources,policy):
    validate_policy(policy);exact(audit['schema'],1,'integer schema');exact(audit['step'],413,'integer413')
    exact(audit['state'],'prepared-internal-baseline-storage-once-only-rights-audit','prepared internal storage audit')
    exact(audit['scope'],'repository-internal-manuscript-audit409-418-only','same finite scope');exact(audit['entry_commit_prefix'],'12bd22a','accepted412 entry')
    for key in policy['null_fields']:exact(audit[key],None,'unselected or unknown '+key)
    for key in policy['false_fields']:exact(audit[key],False,'no native authority approval completion or pause '+key)
    exact(audit['boundaries'],policy['expected_boundaries'],'complete original closed native/approval boundaries');exact(audit['whole_original_requirements_remain_normative'],True,'original norms binding')
    exact(audit['whole_input_references'],sources['inputs'],'all125 whole source inputs')
    packet=json.loads(inputs['packet407']);previous=json.loads(inputs['audit412']);storage=json.loads(inputs['storage404'])
    exact(audit['whole_storage404_context'],storage,'WHOLE404 all branches microsteps baseline phases failures platform rows')
    exact(audit['whole_nine_global_semantic_rules'],packet['semantic_register']['rules'],'all nine complete own-actor global rules')
    for field in ['whole_accepted410_findings','whole_accepted410_clarifications','whole_accepted411_findings']:
        exact(audit[field],previous[field],'WHOLE preceding retained '+field)
    exact(audit['whole_accepted412_findings'],previous['new_findings'],'both whole412 open questions')
    exact(audit['branch_reviews'],policy['expected_branch_reviews'],'all18 exact specific branch assessments')
    exact(len(audit['branch_reviews']),18,'all18 complete branches')
    for row,source in zip(audit['branch_reviews'],storage['all18_original_recovery_branch_reconciliations']):
        exact(row['whole_storage404_reconciliation'],source,'WHOLE exact original branch and prior inactive reconciliation')
        exact(row['id'],source['id'],'exact ordered branch identity');exact(row['is_executable_action_selector'],False,'no branch runtime selector');exact(row['current_recovery_authority'],False,'no branch recovery grant')
    exact(audit['owned_microstep_reviews'],policy['expected_microstep_reviews'],'all9 full microsteps with27 exact paper cut questions')
    exact(len(audit['owned_microstep_reviews']),9,'all9 microsteps')
    for row,source in zip(audit['owned_microstep_reviews'],storage['all9_owned_microstep_reconciliations']):
        exact(row['whole_storage404_microstep'],source,'WHOLE original microstep and its three cuts')
        exact(row['position'],source['position'],'same original ordered microstep')
        exact([c['location'] for c in row['complete_paper_cut_reviews']],['before','within','after'],'all three exact cut questions')
        for cut in row['complete_paper_cut_reviews']:
            exact(cut['actual_effective_native_fault'],None,'paper cut not actual fault');exact(cut['runtime_authority'],False,'no cut execution grant')
    exact(audit['paper_status_cases'],policy['expected_cases'],'all18 complete independent-status paper comparisons')
    for row in audit['paper_status_cases']:exact(row['status_projection'],status_vector(row['case']),'derive separate original scalar statuses without action selection')
    exact(audit['source_storage_wording'],policy['expected_source_storage_wording'],'complete original claim launch storage baseline raw and recovery statements')
    original320=json.loads(inputs['original320']);original324=json.loads(inputs['original324'])
    exact(audit['source_storage_wording'],{'whole_original320_claim_launch_unknown':{k:original320[k] for k in ['claim_contract','launch_contract','unknown_rule']},'whole_original322_commit_contract':json.loads(inputs['original322'])['commit_contract'],'whole_original324_baseline_pkglist_recovery':{k:original324[k] for k in ['baseline_contract','pkglist_contract','recovery_contract']},'whole_original323_recovery_contract':json.loads(inputs['original323'])['recovery_contract'],'whole_inactive_R402_replacements':packet['exact14_inactive_clause_replacements'][7:9]},'direct WHOLE original statement bindings')
    exact(audit['raw_binding_review'],policy['expected_raw_binding_review'],'separate original production bytes audit pin and restoration semantics')
    exact(audit['new_findings'],policy['expected_new_findings'],'one complete action-identity/no-op refinement question')
    for finding in audit['new_findings']:exact(finding['whole_source_storage_wording'],audit['source_storage_wording'],'finding retains WHOLE original source statements')
    exact(audit['interpretation_limit'],policy['expected_interpretation_limit'],'status retention not restore/commit selector or native durability proof')
    exact(audit['remaining_review_and_approval_order'],json.loads(inputs['plan409'])['approval_order'],'independent actual safe review then separate fresh bounded test grant')
    exact(audit['conditional_close_step'],418,'conditional418 target');exact(audit['next_preparable_step_after_complete413_acceptance'],414,'actual413 before414');exact(audit['no_automatic419'],True,'future STOP noautomatic419')
    return True


def review(entry,audit,inputs,source_blobs,sources,policy):
    validate_entry(entry,inputs,policy);validate_sources(inputs,source_blobs,sources,policy);validate_audit(audit,inputs,sources,policy)
    return {'step':413,'state':'prepared-baseline-storage-rights-audit-awaiting-user-acceptance','branches':18,'owned_microsteps':9,'paper_cut_questions':27,'paper_status_cases':18,'retained_open_findings':11,'new_open_questions':1,'runtime_authority':False,'native_cases_run':0,'native_proofs_added':0,'independent_impact_review_accepted':False,'selected_options':None,'approved_contract_migration':None,'current_strong_safe_pause':False,'last_confirmed_strong_safe_pause_step':408,'actual_host_state':'unobserved-not-claimed-absent','actual_live_bindings':None,'actual_global_host_closure':False,'next_preparable_step_after_complete_acceptance':414}
