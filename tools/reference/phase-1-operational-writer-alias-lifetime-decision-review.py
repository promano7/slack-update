#!/usr/bin/env python3
"""Review supplied writer/alias/lifetime decisions only; no native operations."""
import hashlib
import json
import re
POLICY_SHA='7eca8759590cb800b027092613805e4c4f788f6caa861e4f304bf0880b4c4d61'
def sha(raw):return hashlib.sha256(raw).hexdigest()
def canonical(v):return sha(json.dumps(v,sort_keys=True,separators=(',',':'),ensure_ascii=True).encode())
def exact(value,expected,label):
    if type(value) is not type(expected) or canonical(value)!=canonical(expected):raise ValueError(label)
    return True
def validate_policy(p):return exact(canonical(p),POLICY_SHA,'authored381policy substitution')
def validate_acceptance(c,r,p):
    validate_policy(p);exact(canonical(c),p['confirmation_canonical_sha256'],'complete380confirmation')
    exact(canonical(r),p['receipt_canonical_sha256'],'complete uploaded380receipt')
    raw=r['text'].encode('utf-8');exact(sha(raw),c['receipt_sha256'],'unchanged380uploadedbytes');exact(len(raw),c['receipt_size_bytes'],'380size')
    text=r['text'];exact([s for s in text.splitlines() if s.startswith('PASS: ')],p['expected_ordered_PASS_labels380'],'all157ordered380labels')
    for marker in ['Result: PASS (157 passes, 0 failures)','step380_overlay_application_status\tPASS','step380_commit_scope_verification_status\tPASS',
                   '9 files changed, 3133 insertions(+)','[main 7820d1a] '+c['exact_commit_message'],'b50554c..7820d1a  main -> main']:
        exact(text.count(marker),1,'exact single380marker')
    exact(re.findall(r'^ create mode 100644 (.+)$',text,re.M),p['expected_created_paths380'],'exact380creates')
    head='7820d1a (HEAD -> main, origin/main, origin/HEAD) '+c['exact_commit_message']
    exact(text.split('b50554c..7820d1a  main -> main',1)[1].strip().splitlines(),[head,head,'promano@pc-arch ~/Descargas $'],'reportedcleanmatchingheads')
    return True
def validate_baseline(blobs,addition,p):
    validate_policy(p);exact(sorted(blobs),sorted(p['baseline_sha256']),'all1969predecessorpaths')
    exact(sha(addition),p['changelog_addition_sha256'],'exact381prefix')
    for rel,digest in p['baseline_sha256'].items():
        raw=blobs[rel]
        if rel=='CHANGELOG.md':
            if not raw.startswith(addition):raise ValueError('additive381prefix')
            raw=raw[len(addition):]
        exact(sha(raw),digest,'whole accepted380bytes '+rel)
    return True
def validate_inputs(inputs,sources,readme,writer_raw,p):
    validate_policy(p);exact(sorted(inputs),sorted(p['whole_input_paths']),'whole original input set')
    for key,raw in inputs.items():
        exact(sha(raw),p['whole_input_sha256'][key],'wholebyte '+key)
        exact(canonical(json.loads(raw)),p['whole_input_canonical_sha256'][key],'wholecanonical '+key)
    f=json.loads(inputs['freeze378']);exact(sorted(sources),sorted(r['path'] for r in f['review_sources']),'four inert roots')
    for row in f['review_sources']:exact(sha(sources[row['path']]),row['sha256'],'inertsource '+row['path'])
    exact(sha(readme),p['baseline_sha256']['README.md'],'exact README')
    binding=f['full_original_contracts320_327']['324']['document']['writer_resource_map_binding']
    exact(sha(writer_raw),binding['sha256'],'whole original writer map bytes')
    return True
def validate_dossier(d,s,inputs,p):
    validate_policy(p);exact(canonical(d),p['dossier_canonical_sha256'],'whole writer decision dossier')
    exact(canonical(s),p['sources_canonical_sha256'],'primary register')
    f=json.loads(inputs['freeze378']);plan=json.loads(inputs['plan379']);c=f['full_original_contracts320_327']['324']['document']
    exact(d['boundaries'],p['boundaries'],'closed native gates')
    for key in ['guard_contract','baseline_contract','interstage_contract','resource_domains']:
        exact(d['original324_'+key],c[key],'whole324 '+key)
    exact(d['original_writer_resource_map_binding'],c['writer_resource_map_binding'],'original writer map binding')
    exact(d['original377_writer_conflict'],f['full_accepted377_unresolved_conflict_review'][1],'whole377 writer conflict')
    exact(d['original372_writer_blocker'],next(r for r in f['inherited372_feasibility_blockers'] if r['family_id']=='writer-object-alias-exclusion'),'whole372 writer blocker')
    exact([c['id'] for c in d['candidates']],p['candidate_ids'],'seven candidate identities')
    exact([r['id'] for r in d['adversarial_schedules']],p['schedule_ids'],'twelve conditional schedules')
    exact(plan['pause_policy']['original_condition_ids'],p['original_pause_condition_ids'],'nine original conditions')
    return True
def review(d,s,c,r,inputs,sources,readme,writer_raw,p):
    validate_acceptance(c,r,p);validate_inputs(inputs,sources,readme,writer_raw,p);validate_dossier(d,s,inputs,p)
    return json.loads(json.dumps({'step':381,'state':'repository-review-valid-user-acceptance-pending','dossier':d,
         'native_entry_blocked':True,'strong_safe_pause':False,'whole_input_bindings':p['whole_input_sha256'],
         'accepted_predecessor_commit_prefix':'7820d1a','full_commit_id_known':False}))
