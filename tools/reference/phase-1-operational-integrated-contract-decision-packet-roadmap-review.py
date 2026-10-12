#!/usr/bin/env python3
"""Review inactive integrated unselected decision packet and additive roadmap proposals from supplied data only."""
import hashlib
import json
import re

POLICY_SHA = '17c26fbe0a8e691a7ec2383e1b52db73b9ef9e7ce48f2233287b6c6e17889887'

def sha(raw):
    return hashlib.sha256(raw).hexdigest()

def canonical(value):
    return sha(json.dumps(value, sort_keys=True, separators=(',', ':'), ensure_ascii=True).encode())

def exact(value, expected, label):
    if type(value) is not type(expected) or canonical(value) != canonical(expected):
        raise ValueError(label)
    return True

def validate_policy(policy):
    return exact(canonical(policy), POLICY_SHA, 'authored397 policy substitution')

def validate_inputs(inputs, source_blobs, sources, policy):
    validate_policy(policy)
    exact(canonical(sources), policy['fixture_canonical_sha256']['sources'], 'whole source register')
    exact(sorted(inputs), sorted(sources['inputs']), 'all58 original input keys')
    for key, row in sources['inputs'].items():
        exact(sha(inputs[key]), row['sha256'], 'whole original input bytes ' + key)
        exact(canonical(json.loads(inputs[key])), row['canonical_sha256'], 'whole original JSON ' + key)
    frozen = json.loads(inputs['freeze388'])
    inherited = {key: row['path'] for key, row in sources['inputs'].items() if key in frozen['frozen_inputs']['paths']}
    exact(inherited, frozen['frozen_inputs']['paths'], 'all40 original normative references')
    roots = sources['inert_roots'] + sources['reviewer_roots'] + [sources['readme']]
    exact(sorted(source_blobs), sorted(row['path'] for row in roots), 'four inert eighteen reviewer and README roots')
    for row in roots:
        exact(sha(source_blobs[row['path']]), row['sha256'], 'whole source root ' + row['path'])
    return True

def validate_baseline(blobs, baseline, addition, policy, readme_addition):
    validate_policy(policy)
    exact(canonical(baseline), policy['fixture_canonical_sha256']['baseline'], 'whole accepted396 baseline manifest')
    exact(sorted(blobs), sorted(baseline), 'all2098 original repository paths')
    exact(sha(addition), policy['changelog_addition_sha256'], 'exact additive397 CHANGELOG prefix')
    exact(sha(readme_addition), policy['readme_addition_sha256'], 'exact additive397 README prefix')
    for path, digest in baseline.items():
        raw = blobs[path]
        if path == 'CHANGELOG.md':
            if not raw.startswith(addition):
                raise ValueError('missing397 CHANGELOG prefix')
            raw = raw[len(addition):]
        if path == 'README.md':
            if not raw.startswith(readme_addition):
                raise ValueError('missing397 README prefix')
            raw = raw[len(readme_addition):]
        exact(sha(raw), digest, 'whole accepted396 historical bytes ' + path)
    return True

def validate_entry(entry, policy):
    validate_policy(policy)
    exact(canonical(entry), policy['fixture_canonical_sha256']['entry396'], 'whole accepted396 receipt and confirmation')
    raw = entry['receipt']['text'].encode('utf-8')
    exact(sha(raw), policy['predecessor_receipt_sha256'], 'unchanged uploaded396 bytes')
    exact(len(raw), policy['predecessor_receipt_size_bytes'], 'complete396 receipt size')
    text = entry['receipt']['text']
    exact([line for line in text.splitlines() if line.startswith('PASS: ')], policy['required_predecessor_PASS_labels'], 'all506 ordered396 labels')
    exact(re.findall(r'^ create mode 100644 (.+)$', text, re.M), policy['required_predecessor_create_paths'], 'eight exact396 create paths')
    for marker in ['step396_overlay_application_status\tPASS', 'step396_commit_scope_verification_status\tPASS',
                   'Result: PASS (506 passes, 0 failures)', '[main 792525e] Phase 1 step 396: map independent oracle and proposal migration impacts',
                   ' 9 files changed, 122716 insertions(+)', '   866e47a..792525e  main -> main\n']:
        exact(text.count(marker), 1, 'single396 marker '+marker)
    exact(text.split('   866e47a..792525e  main -> main\n')[1], policy['expected_predecessor_tail'], 'clean matching reported396 heads')
    return True

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

def validate_fixtures(entry, baseline, packet, sources, policy):
    validate_policy(policy)
    for name, value in [('entry396', entry), ('baseline', baseline), ('packet', packet), ('sources', sources)]:
        exact(canonical(value), policy['fixture_canonical_sha256'][name], 'whole397 fixture ' + name)
    return True

def pair_disposition(left, right):
    if left['input_key'] == right['input_key']:
        return 'same-brief-alternatives-no-current-joint-selection'
    dispositions = [left['whole_option']['disposition'], right['whole_option']['disposition']]
    if 'defer' in dispositions:
        return 'deferral-leaves-joint-native-selection-blocked'
    if 'amendment-proposal' in dispositions:
        return 'joint-semantic-migration-and-trust-scope-reconciliation-required'
    return 'retained-original-guarantees-joint-native-compatibility-unproven'

def validate_packet_shape(packet, inputs, sources, policy):
    """Check full inactive options, conservative pair coverage and original gates."""
    validate_policy(policy)
    decoded = {key: json.loads(inputs[key]) for key in ['plan389', 'accepted386dossier']+policy['family_input_keys']}
    plan = decoded['plan389']
    exact(packet['schema'], 1, 'integer schema')
    exact(packet['step'], 397, 'integer397 step')
    exact(packet['scope'], plan['scope'], 'exact repository-only scope')
    exact(packet['whole_original_integrated_feasibility_review'], decoded['accepted386dossier'], 'WHOLE unchanged original386 feasibility and candidates')
    exact(packet['whole_plan389_reference'], sources['inputs']['plan389'], 'whole finite plan reference')
    exact(packet['whole_396_impact_reference'], sources['inputs']['oracle_brief396'], 'whole accepted396 impact binding')
    exact(packet['whole_finite_roadmap'], plan['roadmap'], 'full finite389-398 roadmap')
    exact(packet['whole_pause_policy'], plan['pause_policy'], 'whole external final pause policy')
    exact(packet['boundaries'], plan['boundaries'], 'every closed original boundary')
    exact(packet['whole_original_requirements_remain_normative'], True, 'all originals remain normative')
    for key in ['authored_option_pair_coverage_complete', 'impact_coverage_complete']:
        exact(packet[key], True, 'authored complete coverage only')
    for key in ['semantic_migration_complete', 'independent_impact_review_accepted', 'joint_native_compatibility_proven', 'current_step_strong_safe_pause', 'native_authority']:
        exact(packet[key], False, 'no packet promotion '+key)
    for key in ['selected_options', 'approved_joint_specification', 'approved_contract_migration', 'actual_selected_implementation', 'actual_joint_native_graph', 'actual_native_evidence', 'after_confirmed398_next_authorized_stage']:
        exact(packet[key], None, 'no selected actual authority '+key)
    for key in ['native_cases_run', 'native_proofs_added']:
        exact(packet[key], 0, 'no native progress')
    exact(packet['conditional_close_step'], 398, 'finite conditional398')
    exact(packet['next_preparable_step_after_complete397_acceptance'], 398, 'actual397 before398')
    impact = decoded['oracle_brief396']
    exact(impact['impact_coverage_complete'], True, 'full396 authored impact retained')
    for key in ['semantic_migration_complete', 'independent_impact_review_accepted', 'integrated_selection_review_complete']:
        exact(impact[key], False, '396 remains unresolved '+key)
    originals = [(key, index, opt) for key in policy['family_input_keys'] for index, opt in enumerate(decoded[key]['options'])]
    register = packet['option_register']
    exact([r['option_id'] for r in register], policy['expected_option_ids'], 'all26 complete options original order')
    for row, (key, index, opt) in zip(register, originals):
        exact(decoded[key]['selected_option'], None, 'prior source unselected')
        exact(decoded[key]['approved_contract_migration'], None, 'prior source migration unapproved')
        exact(row['input_key'], key, 'exact option source')
        exact(row['path'], sources['inputs'][key]['path'], 'whole original option path')
        exact(row['source_option_index'], index, 'exact source option index')
        exact(row['whole_option'], opt, 'WHOLE original option guarantees/trust/effects/dependencies/evidence/impacts/platforms')
        exact(row['whole_option_canonical_sha256'], canonical(opt), 'whole original option canonical binding')
        original_impact = next(r for r in impact['all_option_impact_reviews'] if r['option_id']==opt['id'])
        exact(row['whole_396_impact_review_canonical_sha256'], canonical(original_impact), 'WHOLE full396 impact row bound')
        for field in ['selected', 'runtime_authority']:
            exact(row[field], False, 'no option promotion '+field)
        for field in ['approved_migration', 'native_joint_compatibility']:
            exact(row[field], None, 'no native option approval '+field)
    decisions = packet['decision_rows']
    exact([[d['id'], d['source_family_input_keys']] for d in decisions], policy['decision_specs'], 'eight whole original decisions and exact source families')
    for row in decisions:
        exact(row['whole_original_conflict'], next(c for c in plan['whole_original_conflicts'] if c['id']==row['id']), 'WHOLE original conflict retained')
        exact(row['available_option_ids'], [o['id'] for key in row['source_family_input_keys'] for o in decoded[key]['options']], 'all corresponding alternatives retained')
        exact(row['explicit_user_decision_required'], True, 'separate user decision still required')
        for field in ['selected_option_ids', 'approved_joint_specification', 'approved_migration']:
            exact(row[field], None, 'no decided conflict '+field)
        for field in ['native_blocker_resolved', 'runtime_authority']:
            exact(row[field], False, 'no conflict promotion '+field)
    expected_pairs = []
    for i, left in enumerate(register):
        for right in register[i+1:]:
            expected_pairs.append({'option_ids': [left['option_id'],right['option_id']], 'whole_option_canonical_sha256': [left['whole_option_canonical_sha256'],right['whole_option_canonical_sha256']], 'review_disposition': pair_disposition(left,right), 'whole_conflict_dependencies': [c['id'] for c in plan['whole_original_conflicts']], 'actual_joint_compatibility': None, 'joint_specification_approved': False, 'selected': False, 'runtime_authority': False})
    exact(len(expected_pairs), policy['expected_pair_count'], 'all325 finite unordered pair questions')
    exact(packet['pair_review_questions'], expected_pairs, 'all exact pair dependencies with no compatibility or approval')
    dimensions = packet['joint_review_dimensions']
    exact([[d['id'],d['source_family_input_keys'],d['required_joint_review']] for d in dimensions], policy['dimension_specs'], 'nine whole concrete joint review dimensions')
    for row in dimensions:
        exact(row['affected_option_ids'], [o['id'] for key in row['source_family_input_keys'] for o in decoded[key]['options']], 'all affected dimension options')
        exact(row['actual_joint_resolution'], None, 'no actual dimension resolution')
        exact(row['native_compatibility_proven'], False, 'no native dimension proof')
        exact(row['current_authority'], False, 'no dimension authority')
    return True

def review(entry, baseline, packet, sources, inputs, source_blobs, policy):
    validate_fixtures(entry, baseline, packet, sources, policy)
    validate_inputs(inputs, source_blobs, sources, policy)
    validate_entry(entry, policy)
    validate_packet_shape(packet, inputs, sources, policy)
    return json.loads(json.dumps({'step':397, 'state':'prepared-integrated-unselected-packet-user-acceptance-pending', 'packet':packet, 'whole_entry396':entry, 'whole_input_bindings':sources['inputs'], 'last_confirmed_repository_pause':388, 'strong_safe_pause':False, 'selected_options':None, 'approved_joint_specification':None, 'approved_contract_migration':None, 'native_authority':False, 'conditional_close_step':398, 'after_actual397_acceptance_next_preparable_step':398, 'next_authorized_stage_after398':None}))
