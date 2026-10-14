#!/usr/bin/env python3
"""Inactive supplied-data revocation comparison; never a native gate."""
import hashlib
import json
import re

POLICY_SHA = '093fe58efcdb111878eb248973f60d17eac3ad949229c24a360898855d517009'

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
    exact(canonical(sources), policy['fixture_canonical_sha256']['sources'], 'whole authored411 source registry')
    exact(sorted(inputs), sorted(sources['inputs']), 'all117 whole JSON inputs')
    for key, row in sources['inputs'].items():
        exact(sha(inputs[key]), row['sha256'], 'whole source bytes ' + key)
        exact(canonical(json.loads(inputs[key])), row['canonical_sha256'], 'whole source value ' + key)
    previous = json.loads(inputs['sources410'])
    inherited = {k: v for k, v in sources['inputs'].items() if k not in policy['new_source_keys']}
    exact(inherited, previous['inputs'], 'all113 original input bindings unchanged')
    exact(sources['inert_roots'], previous['inert_roots'], 'all four native roots remain inert')
    exact(sources['reviewer_roots'][:-1], previous['reviewer_roots'], 'all prior reviewer roots unchanged')
    roots = sources['inert_roots'] + sources['reviewer_roots'] + [sources['readme']]
    exact(sorted(source_blobs), sorted(row['path'] for row in roots), 'all37 source roots')
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
    exact(sorted(blobs), sorted(baseline), 'all2210 historical410 paths')
    for path, digest in baseline.items():
        raw = blobs[path]
        if path in policy['prefixes']:
            prefix = policy['prefixes'][path].encode()
            if not raw.startswith(prefix):
                raise ValueError('missing exact411 additive prefix')
            raw = raw[len(prefix):]
        exact(sha(raw), digest, 'unchanged historical410 bytes ' + path)
    return True


"""Inactive paper reading only; never a native gate, selector or execution grant."""
BASE_FIELDS = ['original_authority_known', 'admission_state_known', 'pre_spend_known',
               'same_identity_known', 'guard_known', 'source_protection_known',
               'envelope_membership_known', 'safe_cut_supported_known',
               'clock_mapping_known', 'within_original_deadline',
               'within_original_spent_budget', 'no_worker_control_channel_known',
               'complete_original_prerequisites_known', 'action_is_original_once_only']
RECOVERY_FIELDS = ['retained_original_recovery_known', 'known_exact_backup', 'dependent_prior_drain_known']
PUBLICATION_FIELDS = ['separate_original_publication_controls_known', 'captured_closed_data_only']


def paper_reading(case):
    exact(case['hypothetical_only'], True, 'paper input only')
    scope = case['scope']
    if scope not in ['forward', 'recovery', 'target-evidence', 'publication']:
        raise ValueError('unknown paper operation scope')
    if case['mode'] not in ['new-admission', 'internal-effect']:
        raise ValueError('unknown paper operation mode')
    request = case['request']
    if request['namespace'] not in ['target', 'publication', 'unknown'] or request['scope'] not in ['none', 'forward', 'recovery', 'all', 'publication', 'unknown'] or request['order'] not in ['none', 'before-admission', 'after-admission', 'unknown']:
        raise ValueError('unknown paper request syntax')
    required = BASE_FIELDS + (RECOVERY_FIELDS if scope in ['recovery', 'target-evidence'] else PUBLICATION_FIELDS if scope == 'publication' else [])
    exact(sorted(case['facts']), sorted(required), 'exact relevant paper prerequisite set')
    denied, unknown = [], []
    for key in required:
        value = case['facts'][key]
        if value is not None and type(value) is not bool:
            raise ValueError('paper fact must be bool or unknown')
        if value is None:
            unknown.append(key)
        elif value is False:
            denied.append(key)
    for key in ['original_forward_failed', 'original_mismatch']:
        if case[key] is not None and type(case[key]) is not bool:
            raise ValueError('original status must remain boolean or unknown')
    if case['outcome'] not in ['known-closed', 'known-open', 'unknown']:
        raise ValueError('unknown paper outcome type')
    if case['qualified_captured_fact'] not in [None, 'hypothetically-qualified-original-target-match', 'hypothetically-qualified-original-mismatch']:
        raise ValueError('invalid qualified hypothetical fact')
    applicable = False
    if request['namespace'] == 'unknown' or request['scope'] == 'unknown':
        applicable = None
        unknown.append('request-namespace-or-scope')
    elif request['scope'] != 'none':
        if request['namespace'] == 'target':
            if request['scope'] not in ['forward', 'recovery', 'all']:
                raise ValueError('invalid target request')
            applicable = scope == 'forward' and request['scope'] in ['forward', 'all'] or scope in ['recovery', 'target-evidence'] and request['scope'] in ['recovery', 'all']
        elif request['namespace'] == 'publication':
            if request['scope'] not in ['publication', 'all']:
                raise ValueError('invalid publication request')
            applicable = scope == 'publication'
    if applicable:
        if case['mode'] == 'new-admission' or request['order'] == 'before-admission':
            denied.append('applicable-request-closes-new-admission')
        elif request['order'] != 'after-admission':
            unknown.append('independent-admission-request-order')
    elif request['scope'] == 'none' and request['order'] != 'none':
        raise ValueError('no request cannot have an order')
    if scope == 'forward' and (case['original_forward_failed'] is True or case['original_mismatch'] is True):
        denied.append('absorbing-original-forward-failure')
    if scope == 'forward' and (case['original_forward_failed'] is None or case['original_mismatch'] is None):
        unknown.append('original-forward-failure-status')
    if denied:
        projection = 'paper-denied-dependent-effect-or-admission'
    elif unknown:
        projection = 'paper-pending-unproved-dependent-effect'
    elif case['mode'] == 'new-admission':
        projection = 'paper-new-admission-question-only'
    elif applicable:
        projection = 'paper-consider-known-pre-request-finite-envelope-only'
    else:
        projection = 'paper-consider-original-envelope-without-applicable-request'
    original = ('original-publication-own-policy-still-due' if scope == 'publication' else
                'original-live-fence-denies-post-request-target-effect' if applicable and case['mode'] == 'internal-effect' and request['order'] == 'after-admission' else
                'original-whole-prerequisites-still-due-no-paper-permission')
    return {'candidate_clause_projection':projection, 'known_denials':denied,
            'unknown_required_facts':unknown, 'request_applies_in_paper_namespace':applicable,
            'original_clause_comparison':original,
            'original_forward_failed':case['original_forward_failed'], 'original_mismatch':case['original_mismatch'],
            'outcome':case['outcome'], 'qualified_captured_fact':case['qualified_captured_fact'],
            'pending_obligations_retained':bool(unknown) or case['outcome'] != 'known-closed' or case['original_forward_failed'] is None or case['original_mismatch'] is None,
            'runtime_authority':False, 'native_observation':None,
            'new_grant_or_right_issued':False, 'unknown_means_no_effect':False,
            'request_or_return_proves_full_drain':False, 'actual_global_host_closure':False,
            'current_original_requirements_remain_normative':True}


def validate_entry(entry, inputs, policy):
    validate_policy(policy)
    exact(canonical(entry), policy['fixture_canonical_sha256']['entry410'], 'WHOLE actual410 supplied entry')
    raw=entry['receipt']['text'].encode('utf-8')
    exact(sha(raw),entry['receipt']['sha256'],'complete410 transcript SHA')
    exact(len(raw),entry['receipt']['size_bytes'],'complete410 transcript length')
    exact([s for s in entry['receipt']['text'].splitlines() if s.startswith('PASS: ')],policy['receipt_pass_labels'],'all69 exact ordered410 PASS')
    exact(re.findall(r'^ create mode 100644 (.+)$',entry['receipt']['text'],re.M),policy['receipt_create_paths'],'eight exact410 creates')
    for marker in policy['receipt_single_markers']:exact(entry['receipt']['text'].count(marker),1,'single410 acceptance marker')
    exact(entry['receipt']['text'].split(policy['receipt_push_marker'])[1],policy['receipt_final_tail'],'reported main push empty status matching a23fabb heads')
    exact(entry['confirmation']['commit_prefix'],'a23fabb','reported accepted410')
    exact(entry['confirmation']['commit_full'],None,'full user Git ID unknown')
    exact(entry['confirmation']['new_strong_safe_pause_confirmed'],False,'intermediate410 not strong pause')
    exact(entry['whole_confirmed409_entry_reference'],policy['expected_prior_entry_reference'],'whole prior accepted409 source')
    exact(json.loads(inputs['actual409_entry'])['confirmation']['last_confirmed_strong_safe_pause_step'],408,'last confirmed pause408 only')
    return True


def validate_audit(audit, inputs, sources, policy):
    validate_policy(policy)
    exact(audit['schema'],1,'integer schema');exact(audit['step'],411,'integer411')
    exact(audit['state'],'prepared-internal-scoped-revocation-paper-audit','prepared internal paper audit')
    exact(audit['scope'],'repository-internal-manuscript-audit409-418-only','same finite scope')
    exact(audit['entry_commit_prefix'],'a23fabb','actual410 prefix')
    for key in policy['null_fields']:exact(audit[key],None,'unselected or unknown '+key)
    for key in policy['false_fields']:exact(audit[key],False,'no independent acceptance native authority or pause '+key)
    exact(audit['boundaries'],policy['expected_boundaries'],'all closed native and approval boundaries')
    exact(audit['whole_input_references'],sources['inputs'],'all117 whole inputs')
    exact(audit['whole_original_requirements_remain_normative'],True,'original norms binding')
    packet=json.loads(inputs['packet407']);previous=json.loads(inputs['audit410'])
    exact(audit['whole_nine_global_semantic_rules'],packet['semantic_register']['rules'],'all nine complete global own-actor dependency rules')
    exact(audit['whole_operation402_context'],json.loads(inputs['operation402']),'WHOLE402 scope/envelope/bootstrap/30nodes/95edges/9windows/23paperquestions retained')
    exact(audit['whole_accepted410_findings'],previous['findings'],'all seven WHOLE preceding open findings retained')
    exact(audit['whole_accepted410_clarifications'],previous['proposed_clarifications'],'both full preceding inactive clarification proposals retained')
    exact(audit['whole_current323_fence_forward_recovery_closure'],{k:json.loads(inputs['original323'])[k] for k in ['fence_contract','forward_contract','recovery_contract','closure_contract']},'complete current original clauses')
    exact(audit['paper_scope_interpretation'],policy['expected_scope_interpretation'],'paper namespaces not selected issuer policy')
    exact(audit['cases'],policy['expected_cases'],'all36 exact full paper cases in authored order')
    exact(len(audit['cases']),36,'36 concrete paper cases')
    for row in audit['cases']:
        exact(row['reading'],paper_reading(row['case']),'derive paper multi-status reading independently of saved result')
        exact(row['runtime_authority'],False,'case does not authorize effects')
        exact(row['native_evidence'],None,'paper case not actual observation')
    exact(audit['new_findings'],policy['expected_new_findings'],'two complete new open specification questions')
    known={r['case']['id'] for r in audit['cases']}
    for finding in audit['new_findings']:
        for id_ in finding['paper_case_ids']:
            if id_ not in known:raise ValueError('finding loses concrete paper challenge')
        exact(finding['whole_source_context'],{k:audit[k] for k in ['whole_current323_fence_forward_recovery_closure','paper_scope_interpretation']},'finding complete source/namespace context')
    exact(audit['interpretation_limit'],policy['expected_interpretation_limit'],'paper model not native gate or complete independently accepted semantics')
    exact(audit['remaining_review_and_approval_order'],json.loads(inputs['plan409'])['approval_order'],'actual independent review then separate fresh explicit native-test grant')
    exact(audit['conditional_close_step'],418,'conditional close418');exact(audit['next_preparable_step_after_complete411_acceptance'],412,'actual acceptance before412')
    exact(audit['no_automatic419'],True,'future STOP noautomatic419')
    return True


def review(entry,audit,inputs,source_blobs,sources,policy):
    validate_entry(entry,inputs,policy);validate_sources(inputs,source_blobs,sources,policy);validate_audit(audit,inputs,sources,policy)
    return {'step':411,'state':'prepared-scoped-revocation-paper-audit-awaiting-user-acceptance','paper_cases':36,'retained_open_findings':7,'new_open_questions':2,'runtime_authority':False,'native_cases_run':0,'native_proofs_added':0,'independent_impact_review_accepted':False,'selected_options':None,'approved_contract_migration':None,'current_strong_safe_pause':False,'last_confirmed_strong_safe_pause_step':408,'actual_host_state':'unobserved-not-claimed-absent','actual_live_bindings':None,'actual_global_host_closure':False,'next_preparable_step_after_complete_acceptance':412}
