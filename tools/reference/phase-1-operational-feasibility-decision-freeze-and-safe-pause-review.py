#!/usr/bin/env python3
"""Review supplied decision-freeze and conditional repository-pause data only."""
import hashlib
import json
import re

POLICY_SHA = '2e8abc0e162680330329f01d5c906d1a2d79f15cc8c7dbf1c2cb01f99be07b75'

def sha(raw):
    return hashlib.sha256(raw).hexdigest()

def canonical(value):
    return sha(json.dumps(value, sort_keys=True, separators=(',', ':'), ensure_ascii=True).encode())

def exact(value, expected, label):
    if type(value) is not type(expected) or canonical(value) != canonical(expected):
        raise ValueError(label)
    return True

def validate_policy(policy):
    return exact(canonical(policy), POLICY_SHA, 'authored388 policy substitution')

def validate_acceptance(confirmation, receipt, policy):
    validate_policy(policy)
    exact(canonical(confirmation), policy['confirmation_canonical_sha256'], 'complete387 confirmation')
    exact(canonical(receipt), policy['receipt_canonical_sha256'], 'complete visible387 transcript')
    raw = receipt['text'].encode('utf-8')
    exact(sha(raw), confirmation['receipt_sha256'], 'exact stored visible387 transcript')
    exact(len(raw), confirmation['receipt_size_bytes'], 'visible387 transcript size')
    text = receipt['text']
    exact([line for line in text.splitlines() if line.startswith('PASS: ')], policy['expected_ordered_PASS_labels387'], 'all211 ordered387 labels')
    for marker in policy['required_receipt_markers387']:
        exact(text.count(marker), 1, 'single387 marker ' + marker)
    exact(re.findall(r'^ create mode 100644 (.+)$', text, re.M), policy['expected_created_paths387'], 'eight387 creates')
    exact(text.split('094af08..086aab2  main -> main', 1)[1], policy['expected_exact_tail387'], 'reported clean matching heads')
    return True

def validate_baseline(blobs, addition, policy):
    validate_policy(policy)
    exact(sorted(blobs), sorted(policy['baseline_sha256']), 'all2025 predecessor paths')
    exact(sha(addition), policy['changelog_addition_sha256'], 'exact388 prefix')
    for rel, digest in policy['baseline_sha256'].items():
        raw = blobs[rel]
        if rel == 'CHANGELOG.md':
            if not raw.startswith(addition):
                raise ValueError('missing additive388 prefix')
            raw = raw[len(addition):]
        exact(sha(raw), digest, 'whole accepted387 bytes ' + rel)
    return True

def validate_inputs(inputs, sources, reviewers, readme, policy):
    validate_policy(policy)
    exact(sorted(inputs), sorted(policy['whole_input_paths']), 'whole40 normative input set')
    for key, raw in inputs.items():
        exact(sha(raw), policy['whole_input_sha256'][key], 'whole byte input ' + key)
        exact(canonical(json.loads(raw)), policy['whole_input_canonical_sha256'][key], 'whole canonical input ' + key)
    freeze = json.loads(inputs['freeze378'])
    exact(sorted(sources), sorted(row['path'] for row in freeze['review_sources']), 'four inert roots')
    for row in freeze['review_sources']:
        exact(sha(sources[row['path']]), row['sha256'], 'inert root ' + row['path'])
    exact(sorted(reviewers), sorted(policy['batch_reviewer_sha256']), 'whole accepted379 through387 reviewers')
    for path, digest in policy['batch_reviewer_sha256'].items():
        exact(sha(reviewers[path]), digest, 'whole batch reviewer ' + path)
    exact(sha(readme), policy['baseline_sha256']['README.md'], 'whole accepted387 README')
    return True

def validate_freeze(freeze, pause, register, inputs, policy):
    validate_policy(policy)
    exact(canonical(freeze), policy['freeze_canonical_sha256'], 'whole388 decision freeze')
    exact(canonical(pause), policy['pause_canonical_sha256'], 'nine whole original pause conditions')
    exact(canonical(register), policy['sources_canonical_sha256'], 'supplied source register')
    plan = json.loads(inputs['plan379'])
    prior = json.loads(inputs['pause378'])
    exact(freeze['boundaries'], plan['boundaries'], 'all original closed boundaries')
    exact(freeze['whole379_roadmap'], plan['roadmap'], 'complete finite379 through388 roadmap')
    exact(freeze['whole379_pause_policy'], plan['pause_policy'], 'complete original pause policy')
    exact(freeze['whole_accepted387_reconciliation'], json.loads(inputs['accepted387dossier']), 'whole unchanged387 reconciliation')
    exact(freeze['frozen_inputs']['paths'], policy['whole_input_paths'], 'whole frozen input references')
    exact(freeze['frozen_inputs']['file_sha256'], policy['whole_input_sha256'], 'whole frozen byte bindings')
    exact(freeze['frozen_inputs']['canonical_sha256'], policy['whole_input_canonical_sha256'], 'whole frozen canonical bindings')
    exact([row['full_prepared_condition378'] for row in pause['conditions']], prior['conditions'], 'all nine complete original prepared conditions including368 and358')
    exact([row['id'] for row in pause['conditions']], plan['pause_policy']['original_condition_ids'], 'original ordered nine identities')
    for index, row in enumerate(pause['conditions']):
        exact(row['position'], index, 'original condition position')
        exact(row['requirement'], prior['conditions'][index]['requirement'], 'whole original requirement')
        exact(row['current388_actual_user_confirmation'], None, 'actual388 confirmation pending')
        exact(row['actual_native_evidence'], None, 'no native proof from pause')
        exact(row['actual_global_host_closure'], False, 'no host closure from pause')
    exact(freeze['actual_strong_safe_pause_confirmed'], False, 'prepared388 not a final receipt')
    exact(pause['actual_strong_safe_pause_confirmed'], False, 'external final confirmation still pending')
    exact(freeze['next_authorized_stage_after388'], None, 'stop after388')
    exact(freeze['no_automatic389'], True, 'no automatic389')
    exact(freeze['whole_original_requirements_normative'], True, 'whole original normative scope retained')
    return True

def review(freeze, pause, register, confirmation, receipt, inputs, sources, reviewers, readme, policy):
    validate_acceptance(confirmation, receipt, policy)
    validate_inputs(inputs, sources, reviewers, readme, policy)
    validate_freeze(freeze, pause, register, inputs, policy)
    return json.loads(json.dumps({
        'step': 388, 'state': 'repository-freeze-valid-final-user-acceptance-pending',
        'freeze': freeze, 'pause': pause, 'whole_input_bindings': policy['whole_input_sha256'],
        'native_entry_blocked': True, 'strong_safe_pause': False,
        'accepted_predecessor_commit_prefix': '086aab2', 'full_commit_id_known': False,
        'final_actual_receipt_and_all_nine_full_conditions_required': True,
        'next_authorized_stage_after388': None, 'no_automatic389': True,
    }))
