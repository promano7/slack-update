#!/usr/bin/env python3
"""Review WHOLE supplied clause-audit data; never run native roots."""
import hashlib
import json
import re

POLICY_SHA = 'f4e90d6e15f3354222d946f51f76291fb0fc5340dbfb30910d8a22c1bdbd3fec'

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
    exact(canonical(sources), policy['fixture_canonical_sha256']['sources'], 'whole authored410 source registry')
    exact(sorted(inputs), sorted(sources['inputs']), 'all113 whole JSON inputs')
    for key, row in sources['inputs'].items():
        exact(sha(inputs[key]), row['sha256'], 'whole source bytes ' + key)
        exact(canonical(json.loads(inputs[key])), row['canonical_sha256'], 'whole source value ' + key)
    previous = json.loads(inputs['sources409'])
    inherited = {k: v for k, v in sources['inputs'].items() if k not in policy['new_source_keys']}
    exact(inherited, previous['inputs'], 'all109 original input bindings unchanged')
    exact(sources['inert_roots'], previous['inert_roots'], 'all four native roots remain inert')
    exact(sources['reviewer_roots'][:-1], previous['reviewer_roots'], 'all prior reviewer roots unchanged')
    roots = sources['inert_roots'] + sources['reviewer_roots'] + [sources['readme']]
    exact(sorted(source_blobs), sorted(row['path'] for row in roots), 'all36 source roots')
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
    exact(sorted(blobs), sorted(baseline), 'all2202 historical409 paths')
    for path, digest in baseline.items():
        raw = blobs[path]
        if path in policy['prefixes']:
            prefix = policy['prefixes'][path].encode()
            if not raw.startswith(prefix):
                raise ValueError('missing exact410 additive prefix')
            raw = raw[len(prefix):]
        exact(sha(raw), digest, 'unchanged historical409 bytes ' + path)
    return True


def replace_pointer(value, path, replacement):
    parent, key = path.rsplit('/', 1)
    container = pointer(value, parent)
    key = key.replace('~1', '/').replace('~0', '~')
    if type(container) is list:
        if not re.fullmatch(r'0|[1-9][0-9]*', key) or int(key) >= len(container):
            raise ValueError('invalid patch index')
        container[int(key)] = replacement
    else:
        if key not in container:
            raise ValueError('patch changes undeclared member')
        container[key] = replacement


def validate_entry(entry, inputs, policy):
    validate_policy(policy)
    exact(canonical(entry), policy['fixture_canonical_sha256']['entry409'], 'WHOLE actual409 supplied entry')
    receipt, confirmation = entry['receipt'], entry['confirmation']
    raw = receipt['text'].encode('utf-8')
    exact(sha(raw), receipt['sha256'], 'complete409 supplied return digest')
    exact(len(raw), receipt['size_bytes'], 'complete409 return length')
    exact(receipt['capture_basis'], confirmation['capture_basis'], 'UTF8 transcription provenance disclosed')
    exact([s for s in receipt['text'].splitlines() if s.startswith('PASS: ')], policy['receipt_pass_labels'], 'all61 exact ordered409 PASS labels')
    exact(re.findall(r'^ create mode 100644 (.+)$', receipt['text'], re.M), policy['receipt_create_paths'], 'all eight exact409 creates')
    for marker in policy['receipt_single_markers']:
        exact(receipt['text'].count(marker), 1, 'single409 acceptance marker')
    exact(receipt['text'].split(policy['receipt_push_marker'])[1], policy['receipt_final_tail'], 'successful reported409 push clean status and matching heads')
    exact(confirmation['commit_prefix'], '90f9f6c', 'reported accepted409')
    exact(confirmation['commit_full'], None, 'full user Git ID remains unknown')
    exact(confirmation['new_strong_safe_pause_confirmed'], False, '409 intermediate checkpoint not new pause')
    exact(entry['whole_confirmed408_entry_reference'], policy['expected_prior_entry_reference'], 'WHOLE prior externally confirmed408 entry retained')
    prior = json.loads(inputs['actual408_entry'])
    exact(prior['confirmation']['strong_safe_pause'], True, 'historical408 external pause retained')
    exact(prior['confirmation']['closed_step_range'], [399, 408], 'historical scoped range unchanged')
    exact(confirmation['last_confirmed_strong_safe_pause_step'], 408, 'last confirmed408 only')
    return True


def validate_patch_views(views, amendments, inputs):
    exact([v['source_input_key'] for v in views], ['original'+str(n) for n in range(320, 328)], 'all eight current contract views')
    for view in views:
        key = view['source_input_key']
        current = json.loads(inputs[key])
        exact(view['whole_current_document'], current, 'WHOLE direct current contract ' + key)
        expected = json.loads(json.dumps(current))
        replacements = [r for r in amendments if r['input_key'] == key]
        for row in replacements:
            exact(pointer(current, row['json_pointer']), row['whole_current_value'], 'original patch value')
            replace_pointer(expected, row['json_pointer'], row['complete_proposed_value'])
        exact(view['inactive_exact_clause_patch_view'], expected, 'derive WHOLE patch from exact replacements only')
        exact(view['exact_replacement_ids_applied'], [r['id'] for r in replacements], 'exact allowed patch paths')
        exact(view['approved_or_activated'], False, 'patch remains inactive')
        exact(view['current_original_document_remains_normative'], True, 'current whole contract normative')
        exact(view['patch_view_is_complete_native_protocol'], False, 'clause patch not native protocol')
    return True


def validate_audit(audit, inputs, sources, policy):
    validate_policy(policy)
    exact(audit['schema'], 1, 'integer schema')
    exact(audit['step'], 410, 'integer410')
    exact(audit['state'], 'prepared-internal-clause-guarantee-loss-audit', 'prepared internal authored audit')
    exact(audit['scope'], 'repository-internal-manuscript-audit409-418-only', 'same bounded scope')
    exact(audit['entry_commit_prefix'], '90f9f6c', 'accepted409 prefix')
    for key in policy['null_fields']:
        exact(audit[key], None, 'no selection approval or actual evidence ' + key)
    for key in policy['false_fields']:
        exact(audit[key], False, 'no independent acceptance runtime pause or completion ' + key)
    exact(audit['boundaries'], policy['expected_boundaries'], 'complete original closed boundaries')
    exact(audit['whole_original_requirements_remain_normative'], True, 'original current norms remain')
    exact(audit['whole_input_references'], sources['inputs'], 'all113 whole input references')
    packet = json.loads(inputs['packet407'])
    exact(audit['manuscript_reference'], sources['inputs']['packet407'], 'same WHOLE existing manuscript')
    exact(audit['whole_completed_plan409_roadmap'], json.loads(inputs['plan409'])['roadmap'], 'whole original finite roadmap retained')
    exact(audit['whole_plan409_audit_rules'], json.loads(inputs['plan409'])['audit_rules'], 'concrete original audit rules retained')
    exact(audit['whole_nine_global_semantic_rules'], packet['semantic_register']['rules'], 'all nine WHOLE global rules apply')
    exact(audit['whole_complete_guarantee_loss_register'], packet['complete_guarantee_loss_and_incompatibility_register'], 'all five WHOLE loss families and known normative incompatibilities')
    clauses = audit['clause_reviews']
    original = packet['exact14_inactive_clause_replacements']
    exact(len(clauses), 14, 'all14 whole clause reviews')
    for index, (row, amendment) in enumerate(zip(clauses, original)):
        exact(row['position'], index, 'original ordered clause position')
        exact(row['whole_frozen_replacement'], amendment, 'WHOLE current and candidate clause wording')
        exact(pointer(json.loads(inputs[amendment['input_key']]), amendment['json_pointer']), amendment['whole_current_value'], 'direct WHOLE current clause')
        exact(row['complete_annotation'], policy['expected_annotations'][index], 'specific complete clause assessment and paper challenge')
        exact(row['all_nine_global_rules_apply'], True, 'local comparison waives no other global rule')
        exact(row['native_observation'], None, 'paper challenge not native observation')
        exact(row['independently_accepted'], False, 'author assessment not independent acceptance')
    assumptions = audit['companion_assumption_reviews']
    exact([r['key'] for r in assumptions], sorted(packet['complete4_additional_trust_and_terminal_assumptions']), 'all four WHOLE companion assumptions')
    for row in assumptions:
        exact(row['whole_assumption'], packet['complete4_additional_trust_and_terminal_assumptions'][row['key']], 'complete companion wording')
        exact(row['complete_annotation'], policy['expected_assumption_annotations'][row['key']], 'specific assumption challenge and qualification')
    views = audit['whole_eight_current_and_inactive_patch_views']
    exact(views, packet['whole8_current_and_inactive_patch_contract_views'], 'all eight WHOLE original current/patch views')
    validate_patch_views(views, original, inputs)
    exact(audit['whole_stage12_comparison'], original[11], 'WHOLE316 stage12 outside eight views included')
    exact(audit['findings'], policy['expected_findings'], 'all seven concrete authored findings retained')
    for finding in audit['findings']:
        exact(finding['whole_clause_source_bindings'], [pointer(audit, p)['whole_frozen_replacement'] for p in finding['audit_clause_pointers']], 'finding binds WHOLE exact current/proposed sources')
        exact(finding['native_proof'], False, 'finding not native failure or proof')
        exact(finding['independent_impact_acceptance'], False, 'finding not independent acceptance')
    exact(audit['proposed_clarifications'], policy['expected_clarifications'], 'two WHOLE inactive clarification proposals')
    for row in audit['proposed_clarifications']:
        source = pointer(audit, row['audit_clause_pointer'])['whole_frozen_replacement']
        exact(row['whole_original_frozen_replacement'], source, 'clarification retains original whole clause')
        exact(row['substitution_authorized'], False, 'clarification not silently applied')
        exact(row['native_authority'], False, 'clarification not test authority')
    exact(audit['comparison_limit'], policy['expected_comparison_limit'], 'clause integrity not complete member or native acceptance')
    exact(audit['remaining_review_and_approval_order'], json.loads(inputs['plan409'])['approval_order'], 'same explicit separate actual native gates')
    exact(audit['conditional_close_step'], 418, 'conditional418 goal')
    exact(audit['next_preparable_step_after_complete410_acceptance'], 411, 'actual410 acceptance before411')
    exact(audit['no_automatic419'], True, 'STOP after future confirmed418')
    return True


def review(entry, audit, inputs, source_blobs, sources, policy):
    validate_entry(entry, inputs, policy)
    validate_sources(inputs, source_blobs, sources, policy)
    validate_audit(audit, inputs, sources, policy)
    return {'step':410, 'state':'prepared-internal-clause-audit-awaiting-user-acceptance',
            'authored_findings':7, 'draft_clarifications':2,
            'selected_options':None, 'approved_contract_migration':None,
            'independent_impact_review_accepted':False, 'runtime_authority':False,
            'native_cases_run':0, 'native_proofs_added':0,
            'last_confirmed_strong_safe_pause_step':408, 'current_strong_safe_pause':False,
            'actual_host_state':'unobserved-not-claimed-absent', 'actual_live_bindings':None,
            'actual_global_host_closure':False,
            'next_preparable_step_after_complete_acceptance':411}
