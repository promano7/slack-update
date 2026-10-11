#!/usr/bin/env python3
"""Review supplied roadmap reconciliation data; never perform native operations."""
import hashlib
import json
import re

POLICY_SHA = 'c7073a01c0c14a178e30e7ba2696e4e6fa8ed351df1a5d3555f0a167f467626f'

def sha(raw):
    return hashlib.sha256(raw).hexdigest()

def canonical(value):
    return sha(json.dumps(value, sort_keys=True, separators=(',', ':'), ensure_ascii=True).encode())

def exact(value, expected, label):
    if type(value) is not type(expected) or canonical(value) != canonical(expected):
        raise ValueError(label)
    return True

def validate_policy(policy):
    return exact(canonical(policy), POLICY_SHA, 'authored387 policy substitution')

def validate_acceptance(confirmation, receipt, policy):
    validate_policy(policy)
    exact(canonical(confirmation), policy['confirmation_canonical_sha256'], 'complete386 confirmation')
    exact(canonical(receipt), policy['receipt_canonical_sha256'], 'complete supplied386 Markdown')
    raw = receipt['text'].encode('utf-8')
    exact(sha(raw), confirmation['receipt_sha256'], 'exact uploaded Markdown bytes')
    exact(len(raw), confirmation['receipt_size_bytes'], 'exact uploaded Markdown size')
    text = receipt['text']
    # Extraction interprets the supplied flattened Markdown, never overwrites its bytes.
    labels = ['PASS: ' + row for row in re.findall(r'PASS: (.*?)(?= PASS:| Result:)', text)]
    exact(labels, policy['expected_ordered_PASS_labels386'], 'all516 ordered labels')
    for marker in policy['required_receipt_markers386']:
        exact(text.count(marker), 1, 'single386 marker: ' + marker)
    creates = re.findall(r' create mode 100644 (.*?)(?=  create mode| Enter passphrase)', text)
    exact([row.replace('\\.', '.') for row in creates], policy['expected_created_paths386'], 'eight386 creates')
    tail = text.split('d457428..094af08  main -> main', 1)[1]
    exact(tail, policy['expected_exact_markdown_tail386'], 'reported clean matching heads without intervening status')
    return True

def validate_baseline(blobs, additions, policy):
    validate_policy(policy)
    exact(sorted(blobs), sorted(policy['baseline_sha256']), 'all2017 predecessor paths')
    exact(sorted(additions), ['CHANGELOG.md', 'README.md'], 'only two additive documents')
    for rel, digest in policy['baseline_sha256'].items():
        raw = blobs[rel]
        if rel in additions:
            exact(sha(additions[rel]), policy['addition_sha256'][rel], 'exact387 prefix ' + rel)
            if not raw.startswith(additions[rel]):
                raise ValueError('missing additive prefix ' + rel)
            raw = raw[len(additions[rel]):]
        exact(sha(raw), digest, 'whole accepted386 bytes ' + rel)
    return True

def validate_inputs(inputs, sources, policy):
    validate_policy(policy)
    exact(sorted(inputs), sorted(policy['whole_input_paths']), 'whole37 input set')
    for key, raw in inputs.items():
        exact(sha(raw), policy['whole_input_sha256'][key], 'whole byte input ' + key)
        exact(canonical(json.loads(raw)), policy['whole_input_canonical_sha256'][key], 'whole canonical input ' + key)
    freeze = json.loads(inputs['freeze378'])
    exact(sorted(sources), sorted(row['path'] for row in freeze['review_sources']), 'four inert roots')
    for row in freeze['review_sources']:
        exact(sha(sources[row['path']]), row['sha256'], 'inert source ' + row['path'])
    return True

def validate_dossier(dossier, register, inputs, readme_prefix, policy):
    validate_policy(policy)
    exact(canonical(dossier), policy['dossier_canonical_sha256'], 'whole387 reconciliation')
    exact(canonical(register), policy['sources_canonical_sha256'], 'supplied source register')
    integrated = json.loads(inputs['accepted386dossier'])
    plan = json.loads(inputs['plan379'])
    exact(dossier['whole_accepted386_integrated_dossier'], integrated, 'whole unchanged386 verdict')
    exact(dossier['whole379_pause_policy'], plan['pause_policy'], 'whole original pause policy')
    exact(dossier['boundaries'], plan['boundaries'], 'all original closed boundaries')
    exact(dossier['whole_original_condition_ids'], plan['pause_policy']['original_condition_ids'], 'all nine original conditions')
    exact(dossier['whole379_step387_roadmap_entry'], next(row for row in plan['roadmap'] if row['step'] == 387), 'original387 scope')
    exact(sha(readme_prefix), dossier['readme_prefix_sha256'], 'whole authored README prefix')
    exact(sha(readme_prefix), policy['addition_sha256']['README.md'], 'independently pinned README prefix')
    exact(dossier['bounded_candidate_verdict_counts'], integrated['bounded_candidate_verdict_counts'], 'unchanged45 verdict counts')
    exact(dossier['current_step_strong_safe_pause'], False, '387 is not a new pause')
    exact(dossier['automatic389'], False, 'no automatic389')
    return True

def review(dossier, register, confirmation, receipt, inputs, sources, readme_prefix, policy):
    validate_acceptance(confirmation, receipt, policy)
    validate_inputs(inputs, sources, policy)
    validate_dossier(dossier, register, inputs, readme_prefix, policy)
    return json.loads(json.dumps({
        'step': 387, 'state': 'repository-review-valid-user-acceptance-pending',
        'dossier': dossier, 'whole_input_bindings': policy['whole_input_sha256'],
        'native_entry_blocked': True, 'strong_safe_pause': False,
        'accepted_predecessor_commit_prefix': '094af08', 'full_commit_id_known': False,
        'next_preparable_step_after_complete387_acceptance': 388, 'automatic389': False,
    }))
