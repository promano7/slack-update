#!/usr/bin/env python3
"""Supplied-data trust/time/drain premise review; never native control."""
import hashlib
import json
import re

POLICY_SHA = 'e323bf6b9a8551dc8ee9ea512228bb6ad163ef083e53abf3344c0a3a6471fcf9'

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
    exact(canonical(sources), policy['fixture_canonical_sha256']['sources'], 'whole authored412 source registry')
    exact(sorted(inputs), sorted(sources['inputs']), 'all121 whole JSON inputs')
    for key, row in sources['inputs'].items():
        exact(sha(inputs[key]), row['sha256'], 'whole source bytes ' + key)
        exact(canonical(json.loads(inputs[key])), row['canonical_sha256'], 'whole source value ' + key)
    previous = json.loads(inputs['sources411'])
    inherited = {k: v for k, v in sources['inputs'].items() if k not in policy['new_source_keys']}
    exact(inherited, previous['inputs'], 'all117 original input bindings unchanged')
    exact(sources['inert_roots'], previous['inert_roots'], 'all four native roots remain inert')
    exact(sources['reviewer_roots'][:-1], previous['reviewer_roots'], 'all prior reviewer roots unchanged')
    roots = sources['inert_roots'] + sources['reviewer_roots'] + [sources['readme']]
    exact(sorted(source_blobs), sorted(row['path'] for row in roots), 'all38 source roots')
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
    exact(sorted(blobs), sorted(baseline), 'all2218 historical411 paths')
    for path, digest in baseline.items():
        raw = blobs[path]
        if path in policy['prefixes']:
            prefix = policy['prefixes'][path].encode()
            if not raw.startswith(prefix):
                raise ValueError('missing exact412 additive prefix')
            raw = raw[len(prefix):]
        exact(sha(raw), digest, 'unchanged historical411 bytes ' + path)
    return True


"""Project hypothetical premise vectors only; no native clock, control or gate."""
FACET_IDS=['protected-original-membership','all-descendants-complete','all-FD-aliases-closed','all-streams-drained','all-inflight-storage-effects-drained','continuous-original-guard','qualified-independent-origin']
RIGHT_IDS=['original-surviving-control-prebound','no-replacement-or-reacquisition','original-fixed-mapping','same-boot-clock-identity','time-provider-available','clock-and-suspend-elapsed-accounting-known','within-original-deadline','original-budget-not-refilled','original-once-only-action-spend-known','complete-source-writer-guard-controls']
ROLE_IDS=['transaction-supervisor','protected-guardian','external-admission-rights-controller','clock-provider','independent-observer-custodian']


def premise_vector(case):
    exact(case['hypothetical_only'],True,'paper premise input only')
    vectors={}
    for field,keys in [('drain_facets',FACET_IDS),('current_right_constraints',RIGHT_IDS),('reported_role_survival',ROLE_IDS)]:
        exact(sorted(case[field]),sorted(keys),'complete original hypothetical premise vector')
        failed,unknown=[],[]
        for key in keys:
            value=case[field][key]
            if value is not None and type(value) is not bool:raise ValueError('premises must be boolean or null')
            if value is False:failed.append(key)
            elif value is None:unknown.append(key)
        vectors[field]={'false_premises':failed,'unknown_premises':unknown,'all_supplied_premises_true':not failed and not unknown}
    for key in ['original_forward_failed','original_mismatch']:
        if case[key] is not None and type(case[key]) is not bool:raise ValueError('original status must remain boolean or null')
    # Survival is a separate report. It never establishes original binding or drain.
    return {'drain_premises':vectors['drain_facets'],
            'current_right_premises':vectors['current_right_constraints'],
            'reported_role_survival':case['reported_role_survival'],
            'original_forward_failed':case['original_forward_failed'],'original_mismatch':case['original_mismatch'],
            'qualified_past_fact':case['qualified_past_fact'],
            'pending_obligations_retained':any(v['unknown_premises'] for v in vectors.values()) or case['unresolved_inflight_or_custody'] or case['original_forward_failed'] is None or case['original_mismatch'] is None,
            'past_facts_establish_current_invariance':False,'known_drain_renews_rights':False,
            'role_survival_establishes_full_drain':False,'role_labels_establish_independence':False,
            'native_observation':None,'runtime_authority':False,'actual_global_host_closure':False}


def validate_entry(entry,inputs,policy):
    validate_policy(policy);exact(canonical(entry),policy['fixture_canonical_sha256']['entry411'],'WHOLE actual411 entry')
    raw=entry['receipt']['text'].encode('utf-8');exact(sha(raw),entry['receipt']['sha256'],'complete411 transcript SHA');exact(len(raw),entry['receipt']['size_bytes'],'complete411 length')
    exact([s for s in entry['receipt']['text'].splitlines() if s.startswith('PASS: ')],policy['receipt_pass_labels'],'all64 ordered411 PASS')
    exact(re.findall(r'^ create mode 100644 (.+)$',entry['receipt']['text'],re.M),policy['receipt_create_paths'],'eight exact411 creates')
    for marker in policy['receipt_single_markers']:exact(entry['receipt']['text'].count(marker),1,'single411 marker')
    exact(entry['receipt']['text'].split(policy['receipt_push_marker'])[1],policy['receipt_final_tail'],'reported main push empty status matching d9e7416 heads')
    exact(entry['confirmation']['commit_prefix'],'d9e7416','accepted411 prefix');exact(entry['confirmation']['commit_full'],None,'full user Git ID unknown')
    exact(entry['confirmation']['new_strong_safe_pause_confirmed'],False,'411 intermediate checkpoint only')
    exact(entry['whole_confirmed410_entry_reference'],policy['expected_prior_entry_reference'],'WHOLE prior410 actual entry')
    exact(json.loads(inputs['actual410_entry'])['confirmation']['last_confirmed_strong_safe_pause_step'],408,'last confirmed repository pause408 only')
    return True


def validate_audit(audit,inputs,sources,policy):
    validate_policy(policy);exact(audit['schema'],1,'integer schema');exact(audit['step'],412,'integer412')
    exact(audit['state'],'prepared-internal-trust-clock-guardian-drain-audit','prepared internal audit')
    exact(audit['scope'],'repository-internal-manuscript-audit409-418-only','same finite scope');exact(audit['entry_commit_prefix'],'d9e7416','accepted411 entry')
    for key in policy['null_fields']:exact(audit[key],None,'unknown or unselected '+key)
    for key in policy['false_fields']:exact(audit[key],False,'no native approval completion or pause '+key)
    exact(audit['boundaries'],policy['expected_boundaries'],'all original closed native/approval boundaries')
    exact(audit['whole_original_requirements_remain_normative'],True,'original norms remain binding')
    exact(audit['whole_input_references'],sources['inputs'],'all121 whole inputs retained')
    packet=json.loads(inputs['packet407']);previous=json.loads(inputs['audit411'])
    exact(audit['whole_nine_global_semantic_rules'],packet['semantic_register']['rules'],'all nine complete own-actor global rules')
    exact(audit['whole_trust401_context'],json.loads(inputs['trust401']),'WHOLE401 seven domains84writer questions21effect16lifetime12paper14platform rows retained')
    loss=json.loads(inputs['loss403']);exact(audit['whole_loss403_context'],loss,'WHOLE403 seven facets five loss roles22paper20platform rows retained')
    exact(FACET_IDS,[r['id'] for r in loss['seven_full_drain_requirements']],'all seven exact original facet identities')
    exact(ROLE_IDS,[r['id'] for r in loss['proposed_loss_roles']],'all five original loss roles')
    exact(audit['whole_accepted410_findings'],previous['whole_accepted410_findings'],'all seven original410 findings')
    exact(audit['whole_accepted410_clarifications'],previous['whole_accepted410_clarifications'],'both complete inactive410 clarifications')
    exact(audit['whole_accepted411_findings'],previous['new_findings'],'both complete open411 specification questions')
    exact(audit['paper_case_reviews'],policy['expected_cases'],'all34 complete authored challenge rows')
    exact(len(audit['paper_case_reviews']),34,'34 complete paper challenges')
    for row in audit['paper_case_reviews']:
        exact(row['premise_projection'],premise_vector(row['case']),'derive separate complete facet/right/status vectors')
        exact(row['whole_required_drain_facets'],loss['seven_full_drain_requirements'],'each challenge retains all WHOLE facet obligations')
        exact(row['native_evidence'],None,'paper challenge not native observation');exact(row['runtime_authority'],False,'no paper effect grant')
    exact(audit['new_findings'],policy['expected_new_findings'],'two complete open suspend/common-loss composition questions')
    known={r['case']['id'] for r in audit['paper_case_reviews']}
    for finding in audit['new_findings']:
        for id_ in finding['paper_case_ids']:
            if id_ not in known:raise ValueError('finding loses concrete challenge')
        exact(finding['whole_source_clock_and_loss_wording'],audit['source_clock_and_loss_wording'],'WHOLE source wording for new finding')
    exact(audit['source_clock_and_loss_wording'],{'whole_current_clock_contract':json.loads(inputs['original323'])['clock_contract'],'whole_frozen_clock_replacement':packet['exact14_inactive_clause_replacements'][10],'whole_shared_trust_wording':json.loads(inputs['trust401'])['whole400_shared_trust_wording'],'whole_guardian_clock_wording':loss['whole400_guardian_clock_joint_wording']},'current and inactive whole shared clock/trust/loss statements')
    exact(audit['interpretation_limit'],policy['expected_interpretation_limit'],'premise conjunction is not actual drain/time/independence proof')
    exact(audit['remaining_review_and_approval_order'],json.loads(inputs['plan409'])['approval_order'],'actual safe joint review then separate fresh native-test grant')
    exact(audit['conditional_close_step'],418,'conditional418 target');exact(audit['next_preparable_step_after_complete412_acceptance'],413,'actual412 acceptance before413');exact(audit['no_automatic419'],True,'STOP after future confirmed418')
    return True


def review(entry,audit,inputs,source_blobs,sources,policy):
    validate_entry(entry,inputs,policy);validate_sources(inputs,source_blobs,sources,policy);validate_audit(audit,inputs,sources,policy)
    return {'step':412,'state':'prepared-trust-clock-guardian-drain-audit-awaiting-user-acceptance','paper_challenges':34,'retained_open_findings':9,'new_open_questions':2,'runtime_authority':False,'native_cases_run':0,'native_proofs_added':0,'independent_impact_review_accepted':False,'selected_options':None,'approved_contract_migration':None,'current_strong_safe_pause':False,'last_confirmed_strong_safe_pause_step':408,'actual_host_state':'unobserved-not-claimed-absent','actual_live_bindings':None,'actual_global_host_closure':False,'next_preparable_step_after_complete_acceptance':413}
