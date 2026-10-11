#!/usr/bin/env python3
"""Review supplied live-revocation decision data only; no native operations."""
import hashlib
import json
import re
POLICY_SHA='b84098131398ceb3003540f3e911037d11493f603cc191331e631900ab54eb70'
def sha(raw):return hashlib.sha256(raw).hexdigest()
def canonical(v):return sha(json.dumps(v,sort_keys=True,separators=(',',':'),ensure_ascii=True).encode())
def exact(value,expected,label):
    if type(value) is not type(expected) or canonical(value)!=canonical(expected):raise ValueError(label)
    return True
def validate_policy(p):return exact(canonical(p),POLICY_SHA,'authored380policy substitution')
def validate_acceptance(c,r,p):
    validate_policy(p);exact(canonical(c),p['confirmation_canonical_sha256'],'complete379confirmation')
    exact(canonical(r),p['receipt_canonical_sha256'],'complete uploaded379receipt')
    raw=r['text'].encode('utf-8');exact(sha(raw),c['receipt_sha256'],'unchanged379uploadedbytes');exact(len(raw),c['receipt_size_bytes'],'379size')
    text=r['text'];exact([s for s in text.splitlines() if s.startswith('PASS: ')],p['expected_ordered_PASS_labels379'],'all155ordered379labels')
    for marker in ['Result: PASS (155 passes, 0 failures)','step379_r1_repair_application_status\tPASS','step379_commit_scope_verification_status\tPASS',
                   '9 files changed, 4018 insertions(+)','[main b50554c] '+c['exact_commit_message'],'c3a141c..b50554c  main -> main']:
        exact(text.count(marker),1,'exactsingle379marker')
    exact(re.findall(r'^ create mode 100644 (.+)$',text,re.M),p['expected_created_paths379'],'exact379creates')
    head='b50554c (HEAD -> main, origin/main, origin/HEAD) '+c['exact_commit_message']
    exact(text.split('c3a141c..b50554c  main -> main',1)[1].strip().splitlines(),[head,head,'promano@pc-arch ~/Descargas $'],'reportedcleanmatchingheads')
    return True
def validate_baseline(blobs,addition,p):
    validate_policy(p);exact(sorted(blobs),sorted(p['baseline_sha256']),'all1961predecessorpaths')
    exact(sha(addition),p['changelog_addition_sha256'],'exact380prefix')
    for rel,digest in p['baseline_sha256'].items():
        raw=blobs[rel]
        if rel=='CHANGELOG.md':
            if not raw.startswith(addition):raise ValueError('additive380prefix')
            raw=raw[len(addition):]
        exact(sha(raw),digest,'whole accepted379bytes '+rel)
    return True
def validate_inputs(inputs,sources,readme,p):
    validate_policy(p);exact(sorted(inputs),sorted(p['whole_input_paths']),'wholeoriginalinputset')
    for key,raw in inputs.items():
        exact(sha(raw),p['whole_input_sha256'][key],'wholebyte '+key)
        exact(canonical(json.loads(raw)),p['whole_input_canonical_sha256'][key],'wholecanonical '+key)
    f=json.loads(inputs['freeze378']);exact(sorted(sources),sorted(r['path'] for r in f['review_sources']),'fourinertroots')
    for row in f['review_sources']:exact(sha(sources[row['path']]),row['sha256'],'inertsource '+row['path'])
    exact(sha(readme),p['baseline_sha256']['README.md'],'exactREADME')
    return True
def validate_dossier(d,s,inputs,p):
    validate_policy(p);exact(canonical(d),p['dossier_canonical_sha256'],'wholedecisiondossier')
    exact(canonical(s),p['sources_canonical_sha256'],'primaryregister')
    f=json.loads(inputs['freeze378']);plan=json.loads(inputs['plan379'])
    exact(d['boundaries'],p['boundaries'],'closednativegates')
    exact(d['original323_fence_contract'],f['full_original_contracts320_327']['323']['document']['fence_contract'],'whole323fence')
    exact(d['original323_forward_contract'],f['full_original_contracts320_327']['323']['document']['forward_contract'],'whole323inflight')
    exact(d['original377_live_revocation_conflict'],f['full_accepted377_unresolved_conflict_review'][0],'whole377conflict')
    exact([c['id'] for c in d['candidates']],p['candidate_ids'],'sixcandidateidentities')
    exact([r['id'] for r in d['adversarial_schedules']],p['schedule_ids'],'tenconditionalschedules')
    exact(plan['pause_policy']['original_condition_ids'],p['original_pause_condition_ids'],'nineoriginalconditions')
    return True
def review(d,s,c,r,inputs,sources,readme,p):
    validate_acceptance(c,r,p);validate_inputs(inputs,sources,readme,p);validate_dossier(d,s,inputs,p)
    return json.loads(json.dumps({'step':380,'state':'repository-review-valid-user-acceptance-pending','dossier':d,
         'native_entry_blocked':True,'strong_safe_pause':False,'whole_input_bindings':p['whole_input_sha256'],
         'accepted_predecessor_commit_prefix':'b50554c','full_commit_id_known':False}))
