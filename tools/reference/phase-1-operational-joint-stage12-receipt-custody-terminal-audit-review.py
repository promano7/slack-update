#!/usr/bin/env python3
"""Supplied declared order/status review; never native publication or closure."""
import hashlib
import json
import re

POLICY_SHA = '359532cd8043c80211f669336b712abae10f843a749f8d966cd24852836b265c'

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
    exact(canonical(sources), policy['fixture_canonical_sha256']['sources'], 'whole authored414 source registry')
    exact(sorted(inputs), sorted(sources['inputs']), 'all129 whole JSON inputs')
    for key, row in sources['inputs'].items():
        exact(sha(inputs[key]), row['sha256'], 'whole source bytes ' + key)
        exact(canonical(json.loads(inputs[key])), row['canonical_sha256'], 'whole source value ' + key)
    previous = json.loads(inputs['sources413'])
    inherited = {k: v for k, v in sources['inputs'].items() if k not in policy['new_source_keys']}
    exact(inherited, previous['inputs'], 'all125 original input bindings unchanged')
    exact(sources['inert_roots'], previous['inert_roots'], 'all four native roots remain inert')
    exact(sources['reviewer_roots'][:-1], previous['reviewer_roots'], 'all prior reviewer roots unchanged')
    roots = sources['inert_roots'] + sources['reviewer_roots'] + [sources['readme']]
    exact(sorted(source_blobs), sorted(row['path'] for row in roots), 'all40 source roots')
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
    exact(sorted(blobs), sorted(baseline), 'all2234 historical413 paths')
    for path, digest in baseline.items():
        raw = blobs[path]
        if path in policy['prefixes']:
            prefix = policy['prefixes'][path].encode()
            if not raw.startswith(prefix):
                raise ValueError('missing exact414 additive prefix')
            raw = raw[len(prefix):]
        exact(sha(raw), digest, 'unchanged historical413 bytes ' + path)
    return True


"""Compare declared paper order and independent statuses, never native closure."""
POSITIVE_FLAGS=['producer_trace_closed','payload_prior_only','receipt_commit_known','receipt_writer_trace_closed','final_object_identity_and_storage_known','consumer_custody_ACK_known','all_external_own_effects_accounted','original_publication_bounds_known']
NEGATIVE_FLAGS=['payload_contains_future_completion','later_unclassified_effect','postrelease_target_or_source_access','republication_or_repeat_proposed']
ROLE_IDS=['producer','stream-collector','external-receipt-writer','independent-final-observer','custody-consumer','independent-verifier']


def publication_vector(case,graph):
    exact(case['hypothetical_only'],True,'hypothetical publication input only')
    exact(sorted(case['positive_flags']),sorted(POSITIVE_FLAGS),'all positive outcome components')
    exact(sorted(case['negative_flags']),sorted(NEGATIVE_FLAGS),'all negative effect questions')
    exact(sorted(case['own_role_controls']),sorted(ROLE_IDS),'all six own actor control premises')
    failed,unknown=[],[]
    for field,keys in [('positive_flags',POSITIVE_FLAGS),('negative_flags',NEGATIVE_FLAGS),('own_role_controls',ROLE_IDS)]:
        for key in keys:
            value=case[field][key]
            if value is not None and type(value) is not bool:raise ValueError('boolean or null publication premise required')
            if value is None:unknown.append(field+'/'+key)
            elif (field=='negative_flags' and value is True) or (field!='negative_flags' and value is False):failed.append(field+'/'+key)
    for key in ['original_forward_failed','original_mismatch']:
        if case[key] is not None and type(case[key]) is not bool:raise ValueError('original status must stay boolean or null')
        if case[key] is None:unknown.append(key)
    trace=case['declared_event_order']
    if type(trace) is not list or any(type(v) is not str or not v for v in trace):raise ValueError('full ordered declaration list required')
    positions={node:[i for i,label in enumerate(trace) if label==node] for node in graph['nodes']}
    extras=[{'position':i,'label':label} for i,label in enumerate(trace) if label not in graph['nodes']]
    duplicates=[{'label':node,'positions':pos} for node,pos in positions.items() if len(pos)>1]
    missing=[node for node,pos in positions.items() if not pos]
    violations,unresolved=[],[]
    for before,after in graph['edges']:
        left,right=positions[before],positions[after]
        if len(left)!=1 or len(right)!=1:unresolved.append([before,after])
        elif left[0]>=right[0]:violations.append([before,after])
    return {'complete_ordered_event_declarations':trace,'known_failed_premises':failed,
            'unknown_premises':unknown,'declared_edge_order_violations':violations,
            'unresolved_declared_edges':unresolved,'missing_declared_nodes':missing,
            'duplicate_label_positions':duplicates,'unclassified_declared_events':extras,
            'declared_graph_order_satisfied':not (violations or unresolved or missing or duplicates or extras),
            'original_forward_failed':case['original_forward_failed'],'original_mismatch':case['original_mismatch'],
            'qualified_target_fact':case['qualified_target_fact'],'qualified_object_fact':case['qualified_object_fact'],
            'pending_obligations_retained':bool(unknown or unresolved or missing or duplicates or extras),
            'native_closure_proven':False,'payload_proves_own_future_completion':False,
            'duplicate_label_proves_observed_native_replay':False,'new_publication_or_target_right':False,
            'runtime_authority':False,'native_evidence':None,'actual_global_host_closure':False}


def validate_entry(entry,inputs,policy):
    validate_policy(policy);exact(canonical(entry),policy['fixture_canonical_sha256']['entry413'],'WHOLE actual413 entry')
    raw=entry['receipt']['text'].encode('utf-8');exact(sha(raw),entry['receipt']['sha256'],'complete413 transcript SHA');exact(len(raw),entry['receipt']['size_bytes'],'complete413 length')
    exact([s for s in entry['receipt']['text'].splitlines() if s.startswith('PASS: ')],policy['receipt_pass_labels'],'all79 ordered413 PASS')
    exact(re.findall(r'^ create mode 100644 (.+)$',entry['receipt']['text'],re.M),policy['receipt_create_paths'],'eight exact413 creates')
    for marker in policy['receipt_single_markers']:exact(entry['receipt']['text'].count(marker),1,'single413 marker')
    exact(entry['receipt']['text'].split(policy['receipt_push_marker'])[1],policy['receipt_final_tail'],'reported main push empty status matching5079219heads')
    exact(entry['confirmation']['commit_prefix'],'5079219','accepted413 prefix');exact(entry['confirmation']['commit_full'],None,'full user Git ID unknown');exact(entry['confirmation']['new_strong_safe_pause_confirmed'],False,'413 intermediate checkpoint only')
    exact(entry['whole_confirmed412_entry_reference'],policy['expected_prior_entry_reference'],'WHOLE actual prior412 entry');exact(json.loads(inputs['actual412_entry'])['confirmation']['last_confirmed_strong_safe_pause_step'],408,'last confirmed repository pause408 only')
    return True


def validate_audit(audit,inputs,sources,policy):
    validate_policy(policy);exact(audit['schema'],1,'integer schema');exact(audit['step'],414,'integer414')
    exact(audit['state'],'prepared-internal-stage12-receipt-custody-terminal-audit','prepared internal terminal audit');exact(audit['scope'],'repository-internal-manuscript-audit409-418-only','same finite scope');exact(audit['entry_commit_prefix'],'5079219','accepted413 entry')
    for key in policy['null_fields']:exact(audit[key],None,'unknown or unselected '+key)
    for key in policy['false_fields']:exact(audit[key],False,'no native authority approval completion or pause '+key)
    exact(audit['boundaries'],policy['expected_boundaries'],'complete original closed boundaries');exact(audit['whole_original_requirements_remain_normative'],True,'original norms binding');exact(audit['whole_input_references'],sources['inputs'],'all129 whole input bindings')
    packet=json.loads(inputs['packet407']);previous=json.loads(inputs['audit413']);publication=json.loads(inputs['publication405'])
    exact(audit['whole_nine_global_semantic_rules'],packet['semantic_register']['rules'],'all nine complete own-actor global rules')
    exact(audit['whole_publication405_context'],publication,'WHOLE405 original stage causal review10events6roles24cases3replacements2graphs retained')
    for field in ['whole_accepted410_findings','whole_accepted410_clarifications','whole_accepted411_findings','whole_accepted412_findings']:exact(audit[field],previous[field],'WHOLE preceding open record '+field)
    exact(audit['whole_accepted413_findings'],previous['new_findings'],'whole413 action-identity open question')
    current=json.loads(inputs['publication_requirements316'])['immutable_design_facts']['stages'][12]
    exact(audit['whole_current316_stage12'],current,'WHOLE current original stage12 not a producer subset')
    exact(audit['whole_frozen_inactive_stage_and_terminal_replacements'],packet['exact14_inactive_clause_replacements'][11:14],'all three exact whole inactive stage/publication/crossclosure replacements')
    exact(audit['event_reviews'],policy['expected_event_reviews'],'all10 complete specific event comparisons')
    for row,source in zip(audit['event_reviews'],publication['all10_event_joint_reconciliations']):
        exact(row['whole_publication405_event'],source,'WHOLE original event and source requirement');exact(row['event_id'],source['whole_original394_event']['event_id'],'same ordered event identity');exact(row['runtime_authority'],False,'no event effect grant')
    exact(audit['role_reviews'],policy['expected_role_reviews'],'all6 complete own-actor obligations')
    for row,source in zip(audit['role_reviews'],publication['all6_external_role_obligation_questions']):exact(row['whole_publication405_role'],source,'WHOLE source role control/drain/origin/custody requirement');exact(row['is_exempt_observer'],False,'no observer role exemption')
    graph=publication['whole394_declared_graph_questions'][1];exact(audit['whole_declared_comparison_graph'],graph,'whole existing declared graph,not a new implementation')
    exact(audit['paper_publication_cases'],policy['expected_cases'],'all28 exact complete causal/status paper cases')
    for row in audit['paper_publication_cases']:exact(row['publication_projection'],publication_vector(row['case'],graph),'derive declared partial order and separate outcomes without closure claim')
    exact(audit['new_findings'],policy['expected_new_findings'],'one complete subject/collector membership question')
    for finding in audit['new_findings']:
        exact(finding['whole_subject_trace_event'],publication['all10_event_joint_reconciliations'][3],'WHOLE collector-origin subject-closure event')
        exact(finding['whole_collector_role'],publication['all6_external_role_obligation_questions'][1],'WHOLE collector own-effect duty')
    exact(audit['interpretation_limit'],policy['expected_interpretation_limit'],'order checker not native graph closure or protocol proof')
    exact(audit['remaining_review_and_approval_order'],json.loads(inputs['plan409'])['approval_order'],'actual safe independent review then separate fresh native grant')
    exact(audit['conditional_close_step'],418,'conditional418 target');exact(audit['next_preparable_step_after_complete414_acceptance'],415,'actual414 before415');exact(audit['no_automatic419'],True,'future STOP noautomatic419')
    return True


def review(entry,audit,inputs,source_blobs,sources,policy):
    validate_entry(entry,inputs,policy);validate_sources(inputs,source_blobs,sources,policy);validate_audit(audit,inputs,sources,policy)
    return {'step':414,'state':'prepared-stage12-receipt-custody-audit-awaiting-user-acceptance','event_reviews':10,'own_role_reviews':6,'paper_cases':28,'retained_open_findings':12,'new_open_questions':1,'runtime_authority':False,'native_cases_run':0,'native_proofs_added':0,'independent_impact_review_accepted':False,'selected_options':None,'approved_contract_migration':None,'current_strong_safe_pause':False,'last_confirmed_strong_safe_pause_step':408,'actual_host_state':'unobserved-not-claimed-absent','actual_live_bindings':None,'actual_global_host_closure':False,'next_preparable_step_after_complete_acceptance':415}
