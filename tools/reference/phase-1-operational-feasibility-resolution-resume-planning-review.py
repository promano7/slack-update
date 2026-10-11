#!/usr/bin/env python3
"""Review supplied repository planning data only; no runtime capabilities."""
import hashlib
import json
import re

POLICY_SHA = '46af62e770e852d211b709d0ce8ed2583fc703e14f427519956e1b032483a37f'
PLAN_SHA = '226bf153118c650a3965344dea7f8b7a55a332a41ee378bf4e3c47b4c4bababf'

def sha(raw):
    return hashlib.sha256(raw).hexdigest()

def canonical(value):
    return sha(json.dumps(value, sort_keys=True, separators=(',', ':'), ensure_ascii=True).encode())

def exact(value, expected, label):
    if type(value) is not type(expected) or canonical(value) != canonical(expected):
        raise ValueError(label)
    return True

def validate_policy(policy):
    exact(canonical(policy), POLICY_SHA, 'authored policy substitution')
    return True

def validate_acceptance(confirmation, receipt, conditions, policy):
    validate_policy(policy)
    for value, key in [(confirmation,'confirmation_canonical_sha256'),
                       (receipt,'receipt_canonical_sha256'),
                       (conditions,'conditions_canonical_sha256')]:
        exact(canonical(value), policy[key], 'complete external378 acceptance changed')
    raw = receipt['text'].encode('utf-8')
    exact(sha(raw), confirmation['receipt_sha256'], 'original uploaded378 bytes')
    exact(len(raw), confirmation['receipt_size_bytes'], 'original uploaded378 size')
    text = receipt['text']
    exact([s for s in text.splitlines() if s.startswith('PASS: ')],
          policy['expected_ordered_PASS_labels378'], 'all ordered412 predecessor labels')
    for key in ['expected_summary378','expected_commit_stats378','expected_push378']:
        if text.count(policy[key]) != 1:
            raise ValueError('missing or repeated predecessor marker '+key)
    exact(text.count('[main c3a141c] '+policy['expected_commit_message378']), 1, 'exact378 commit')
    exact(re.findall(r'^ create mode 100644 (.+)$', text, re.M),
          policy['expected_created_paths378'], 'exact378 new path order')
    head='c3a141c (HEAD -> main, origin/main, origin/HEAD) '+policy['expected_commit_message378']
    exact(text.count(head), 2, 'matching reported heads')
    exact([r['id'] for r in conditions['confirmed_conditions']],
          policy['original_pause_condition_ids'], 'original nine condition order')
    exact(confirmation['step'],378,'accepted predecessor step')
    exact(confirmation['strong_safe_pause'],True,'scoped378 confirmed pause')
    exact(confirmation['commit_full'],None,'full reported commit unknown')
    exact(confirmation['actual_global_host_closure'],False,'no global closure')
    for row in conditions['confirmed_conditions']:
        exact(row['actual_native_evidence'],None,'no native evidence promoted')
        exact(row['actual_global_host_closure'],False,'no condition global closure')
    return True

def validate_plan(plan, freeze, policy):
    validate_policy(policy)
    exact(canonical(plan), PLAN_SHA, 'frozen decision plan changed')
    exact(plan['schema'],1,'integer plan schema')
    exact(plan['boundaries'],policy['boundaries'],'closed native and project gates')
    exact([r['step'] for r in plan['roadmap']],list(range(379,389)),'finite ten-step order')
    exact([r['entry_requires_confirmed_step'] for r in plan['roadmap']],list(range(378,388)),
          'complete predecessor acceptance before each step')
    for row in plan['roadmap']:
        for key in ['runtime_authorized','native_proof_discharge_allowed',
                    'implementation_authorized','C_development_authorized','native_components_selected']:
            exact(row[key],False,'review is not authority '+key)
    exact([r['id'] for r in plan['conflict_assignments']],
          [r['id'] for r in freeze['full_accepted377_unresolved_conflict_review']],
          'all whole original conflicts assigned')
    exact(plan['normative_inputs']['whole21_inherited_inputs'],freeze['frozen_inputs'],
          'full inherited input bindings')
    exact(plan['normative_inputs']['four_inert_review_sources'],freeze['review_sources'],
          'whole original review source roles')
    exact(plan['pause_policy']['original_condition_ids'],policy['original_pause_condition_ids'],
          'all nine original pause conditions')
    return True

def validate_inputs(inputs, sources, readme, policy):
    validate_policy(policy)
    exact(sorted(inputs),sorted(policy['whole_input_paths']),'whole input set')
    for key, raw in inputs.items():
        exact(sha(raw),policy['whole_input_sha256'][key],'whole input byte binding '+key)
        exact(canonical(json.loads(raw)),policy['whole_input_canonical_sha256'][key],
              'whole input canonical binding '+key)
    freeze=json.loads(inputs['freeze378'])
    exact(sorted(sources),sorted(r['path'] for r in freeze['review_sources']), 'four inert roots')
    for row in freeze['review_sources']:
        exact(sha(sources[row['path']]),row['sha256'],'inert root bytes '+row['path'])
        exact(len(sources[row['path']]),row['size_bytes'],'inert root size '+row['path'])
        exact(row['execution_authorized'],False,'historical source stays inert')
    exact(sha(readme),policy['baseline_sha256']['README.md'],'README remains exact378')
    return True

def validate_baseline(blobs, addition, policy):
    validate_policy(policy)
    exact(sorted(blobs),sorted(policy['baseline_sha256']),'complete accepted378 file set')
    if not isinstance(addition,bytes) or not addition or not blobs['CHANGELOG.md'].startswith(addition):
        raise ValueError('additive CHANGELOG prefix missing')
    exact(sha(addition),policy['changelog_addition_sha256'],'authored CHANGELOG addition')
    for rel, digest in policy['baseline_sha256'].items():
        raw=blobs[rel][len(addition):] if rel=='CHANGELOG.md' else blobs[rel]
        exact(sha(raw),digest,'accepted378 bytes '+rel)
    return True

def review(plan, confirmation, receipt, conditions, inputs, sources, readme, policy):
    validate_acceptance(confirmation,receipt,conditions,policy)
    validate_inputs(inputs,sources,readme,policy)
    freeze=json.loads(inputs['freeze378'])
    validate_plan(plan,freeze,policy)
    # Return detached whole rows and references; no status promotion or execution.
    return json.loads(json.dumps({
        'step':379,'state':'repository-review-valid-user-acceptance-pending',
        'boundaries':plan['boundaries'],'roadmap':plan['roadmap'],
        'full_original_conflicts':freeze['full_accepted377_unresolved_conflict_review'],
        'whole378_freeze_sha256':sha(inputs['freeze378']),
        'whole_inherited_input_bindings':freeze['frozen_inputs'],
        'whole_original_conditions':conditions['confirmed_conditions'],
        'native_entry_blocked':True,'current_pause_confirmed':False,
        'conditional_pause_step':388,'full_commit_id_known':False,
        'reported_predecessor_commit_prefix':'c3a141c',
    }))
