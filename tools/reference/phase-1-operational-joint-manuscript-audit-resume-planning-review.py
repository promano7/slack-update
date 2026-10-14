#!/usr/bin/env python3
"""Review a bounded manuscript-audit plan using supplied bytes only."""
import hashlib
import json
import re

POLICY_SHA = '43e774f576c028708bcf2e60ec880f026867547557fe452ce2ed483140e97941'


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


def validate_entry(entry, inputs, policy):
    validate_policy(policy)
    exact(canonical(entry), policy['fixture_canonical_sha256']['entry408'], 'WHOLE supplied408 external entry')
    confirmation, receipt = entry['confirmation'], entry['receipt']
    raw = receipt['text'].encode('utf-8')
    exact(sha(raw), receipt['sha256'], 'complete408 return digest')
    exact(len(raw), receipt['size_bytes'], 'complete408 return size')
    exact(receipt['capture_basis'], confirmation['capture_basis'], 'disclosed transcription provenance')
    exact([s for s in receipt['text'].splitlines() if s.startswith('PASS: ')], receipt['ordered_PASS_labels'], 'all95 ordered labels')
    exact(len(receipt['ordered_PASS_labels']), 95, '95 complete PASS labels')
    exact(re.findall(r'^ create mode 100644 (.+)$', receipt['text'], re.M), receipt['exact_created_paths'], 'eight exact creates')
    for marker in policy['receipt_single_markers']:
        exact(receipt['text'].count(marker), 1, 'single actual408 acceptance marker')
    exact(receipt['text'].split(receipt['reported_push_marker'])[1], receipt['reported_final_tail'], 'reported push empty status and matching a81a741 heads')
    exact(confirmation['commit_prefix'], 'a81a741', 'reported accepted408 prefix')
    exact(confirmation['commit_full'], None, 'full user Git ID unknown')
    external = entry['external_conditions']
    freeze = json.loads(inputs['freeze408'])
    exact([c['whole_prepared408_condition'] for c in external['conditions']], freeze['conditions'], 'all nine WHOLE prepared408 and nested conditions')
    exact([c['position'] for c in external['conditions']], list(range(9)), 'ordered external conditions')
    exact([c['id'] for c in external['conditions']], [c['id'] for c in freeze['conditions']], 'same whole condition identities')
    exact(external['scope'], 'repository-joint-contract-proposal399-408-only', 'historical confirmed scope never expanded')
    exact(external['prepared_freeze_canonical_sha256'], canonical(freeze), 'whole prepared freeze binding')
    exact(external['prepared_conditions_canonical_sha256'], canonical(freeze['conditions']), 'whole prepared conditions binding')
    exact(external['complete_final_receipt_sha256'], receipt['sha256'], 'external confirmation uses actual final receipt')
    exact(external['all_nine_whole_conditions_confirmed'], True, 'all nine externally confirmed for old scope')
    exact(entry['current']['actual_strong_safe_pause_confirmed'], True, 'accepted408 historical pause')
    exact(entry['current']['batch_stopped'], True, 'old block stopped')
    exact(entry['current']['next_authorized_stage_after408'], None, 'old block did not authorize409')
    for condition in external['conditions']:
        exact(condition['confirmed_repository_scope_only'], True, 'external confirmation repository only')
        exact(condition['actual_native_evidence'], None, 'no native evidence')
        exact(condition['actual_global_host_closure'], False, 'no global host closure')
    return True


def validate_sources(inputs, source_blobs, sources, policy):
    validate_policy(policy)
    exact(canonical(sources), policy['fixture_canonical_sha256']['sources'], 'whole authored409 source registry')
    exact(sorted(inputs), sorted(sources['inputs']), 'all109 whole JSON inputs')
    for key, row in sources['inputs'].items():
        exact(sha(inputs[key]), row['sha256'], 'whole source bytes ' + key)
        exact(canonical(json.loads(inputs[key])), row['canonical_sha256'], 'whole source value ' + key)
    previous = json.loads(inputs['sources408'])
    inherited = {k: v for k, v in sources['inputs'].items() if k not in ['freeze408', 'policy408', 'sources408']}
    exact(inherited, previous['inputs'], 'all106 original input bindings unchanged')
    exact(sources['inert_roots'], previous['inert_roots'], 'all four native roots remain inert')
    exact(sources['reviewer_roots'][:-1], previous['reviewer_roots'], 'all prior reviewer roots unchanged')
    roots = sources['inert_roots'] + sources['reviewer_roots'] + [sources['readme']]
    exact(sorted(source_blobs), sorted(row['path'] for row in roots), 'all35 source roots')
    for row in roots:
        exact(sha(source_blobs[row['path']]), row['sha256'], 'whole root bytes ' + row['path'])
    for row in sources['inert_roots']:
        exact(row['execution_authorized'], False, 'native root never dispatched')
        exact(row['actual_native_binding'], None, 'no native binding')
    return True


def validate_packet_bindings(packet, inputs):
    # This checks source identity and completeness, not independent semantic acceptance.
    exact(packet, json.loads(inputs['packet407']), 'WHOLE frozen407 manuscript')
    exact(packet, json.loads(inputs['freeze408'])['whole_accepted407_packet'], 'same WHOLE408 frozen manuscript')
    exact(packet['whole_original_requirements_remain_normative'], True, 'original clauses still normative')
    amendments = packet['exact14_inactive_clause_replacements']
    exact(len(amendments), 14, 'all14 exact inactive amendments')
    for row in amendments:
        original = json.loads(inputs[row['input_key']])
        exact(row['whole_current_value'], pointer(original, row['json_pointer']), 'direct original clause binding')
        exact(row['replacement_approved'], False, 'no amendment approved')
    categories = packet['all15_category1286_whole_member_acceptance_matrix']
    oracle = json.loads(inputs['oracle_brief396'])['impact_categories']
    exact([c['category_id'] for c in categories], [c['id'] for c in oracle], 'all15 original categories')
    parsed = {}
    total = 0
    for category, original_category in zip(categories, oracle):
        exact(category['ordered_member_ids'], original_category['ordered_member_ids'], 'all original member identities and order')
        exact([m['member_id'] for m in category['members']], category['ordered_member_ids'], 'no skipped member')
        for member in category['members']:
            key = member['source_input_key']
            if key not in parsed:
                parsed[key] = json.loads(inputs[key])
            whole = pointer(parsed[key], member['source_json_pointer'])
            exact(member['whole_original_member'], whole, 'WHOLE direct original member')
            exact(member['whole_original_member_canonical_sha256'], canonical(whole), 'whole original member canonical binding')
            criterion = member['complete_candidate_acceptance_criterion']
            exact(criterion['independently_accepted'], False, 'author criterion not independent approval')
            exact(criterion['actual_native_evidence'], None, 'no native member evidence')
            exact(criterion['native_proof'], False, 'paper member not native proof')
            exact(criterion['runtime_authority'], False, 'no member runtime grant')
            total += 1
    exact(total, 1286, 'all1286 ordered members')
    return True


def validate_plan(plan, entry, inputs, sources, policy):
    validate_policy(policy)
    exact(plan['schema'], 1, 'integer schema')
    exact(plan['step'], 409, 'integer409')
    exact(plan['state'], 'prepared-bounded-internal-manuscript-audit-plan', 'plan not completed audit')
    exact(plan['scope'], 'repository-internal-manuscript-audit409-418-only', 'finite repository scope')
    exact(plan['entry_commit_prefix'], 'a81a741', 'reported accepted408')
    exact(plan['full_commit_id'], None, 'no invented full Git ID')
    for key in policy['null_fields']:
        exact(plan[key], None, 'pending decision or actual evidence ' + key)
    for key in policy['false_fields']:
        exact(plan[key], False, 'no approval native progress or current pause ' + key)
    exact(plan['whole_original_requirements_remain_normative'], True, 'current original norms')
    exact(plan['authorization_basis'], policy['expected_authorization_basis'], 'new user request permits bounded repository work only')
    exact(plan['boundaries'], policy['expected_boundaries'], 'all closed boundaries with historical408 pause')
    exact(plan['whole_input_references'], sources['inputs'], 'all whole original inputs available')
    exact(plan['whole_source_root_references'], sources['inert_roots'] + sources['reviewer_roots'] + [sources['readme']], 'whole source roots retained')
    packet = json.loads(inputs['packet407'])
    validate_packet_bindings(packet, inputs)
    exact(plan['manuscript_reference'], sources['inputs']['packet407'], 'whole407 manuscript source')
    exact(plan['frozen_manuscript_reference'], sources['inputs']['freeze408'], 'whole408 frozen manuscript source')
    exact(plan['whole_nine_joint_dimensions'], [r['whole_original397_dimension'] for r in packet['all9_whole_joint_dimension_answers']], 'all nine WHOLE joint review questions')
    exact(plan['amendment_review_order'], [r['id'] for r in packet['exact14_inactive_clause_replacements']], 'all14 amendments in source order')
    exact(plan['member_category_review_order'], [r['category_id'] for r in packet['all15_category1286_whole_member_acceptance_matrix']], 'all15 member categories')
    exact(plan['roadmap'], policy['expected_roadmap'], 'concrete finite roadmap with predecessor gates')
    exact([r['step'] for r in plan['roadmap']], list(range(409, 419)), 'ten steps only')
    for row in plan['roadmap']:
        exact(row['complete_predecessor_acceptance_required'], row['step'] - 1, 'no successor without full actual acceptance')
        exact(row['native_execution_authorized'], False, 'no roadmap native grant')
        exact(row['independent_acceptance_claimed'], False, 'same-author audit not independent acceptance')
    mapped = {d for row in plan['roadmap'] for d in row['joint_dimension_ids']}
    exact(sorted(mapped), sorted(d['id'] for d in plan['whole_nine_joint_dimensions']), 'every joint dimension assigned')
    exact(plan['audit_rules'], policy['expected_audit_rules'], 'falsifiable paper findings and bounded remedies')
    exact(plan['approval_order'], policy['expected_approval_order'], 'separate normative and actual native gates')
    exact(plan['pause_policy'], policy['expected_pause_policy'], 'all WHOLE conditions plus current block external close')
    conditions = entry['external_conditions']['conditions']
    exact(plan['pause_policy']['condition_ids'], [c['id'] for c in conditions], 'all nine complete inherited conditions')
    for row, original in zip(plan['pause_policy']['condition_references'], conditions):
        exact(pointer(entry, row['entry_json_pointer']), original['whole_prepared408_condition'], 'direct WHOLE nested condition reference')
        exact(row['whole_condition_canonical_sha256'], canonical(original['whole_prepared408_condition']), 'whole nested condition binding')
    return True


def validate_fixtures(fixtures, policy):
    validate_policy(policy)
    exact(sorted(fixtures), sorted(policy['fixture_canonical_sha256']), 'exact authored fixture set')
    for key, value in fixtures.items():
        exact(canonical(value), policy['fixture_canonical_sha256'][key], 'whole authored fixture ' + key)
    return True


def validate_repository(blobs, baseline, policy):
    validate_policy(policy)
    exact(sorted(blobs), sorted(baseline), 'all2194 historical408 paths')
    for path, digest in baseline.items():
        raw = blobs[path]
        if path in policy['prefixes']:
            prefix = policy['prefixes'][path].encode()
            if not raw.startswith(prefix):
                raise ValueError('missing exact409 additive prefix')
            raw = raw[len(prefix):]
        exact(sha(raw), digest, 'unchanged historical408 bytes ' + path)
    return True


def review(entry, plan, inputs, source_blobs, sources, policy):
    validate_entry(entry, inputs, policy)
    validate_sources(inputs, source_blobs, sources, policy)
    validate_plan(plan, entry, inputs, sources, policy)
    return {'step': 409, 'state': 'prepared-internal-audit-plan-awaiting-user-acceptance',
            'last_confirmed_strong_safe_pause_step': 408, 'conditional_close_step': 418,
            'current_strong_safe_pause': False, 'independent_impact_review_accepted': False,
            'selected_options': None, 'approved_contract_migration': None,
            'runtime_authority': False, 'native_cases_run': 0, 'native_proofs_added': 0,
            'actual_host_state': 'unobserved-not-claimed-absent', 'actual_live_bindings': None,
            'actual_global_host_closure': False, 'next_preparable_step_after_complete_acceptance': 410}
