#!/usr/bin/env python3
"""Review supplied integrated bounded feasibility verdicts only; no native operations."""
import hashlib
import json
import re
POLICY_SHA='18820eac74490f50774c20e0ce14dc86f41b05332f2e0a28f48e2493ffac3a5d'
def sha(raw):return hashlib.sha256(raw).hexdigest()
def canonical(v):return sha(json.dumps(v,sort_keys=True,separators=(',',':'),ensure_ascii=True).encode())
def exact(value,expected,label):
    if type(value) is not type(expected) or canonical(value)!=canonical(expected):raise ValueError(label)
    return True
def validate_policy(p):return exact(canonical(p),POLICY_SHA,'authored386policy substitution')
def validate_acceptance(c,r,p):
    validate_policy(p);exact(canonical(c),p['confirmation_canonical_sha256'],'complete385confirmation')
    exact(canonical(r),p['receipt_canonical_sha256'],'complete uploaded385receipt')
    raw=r['text'].encode('utf-8');exact(sha(raw),c['receipt_sha256'],'unchanged385uploadedbytes');exact(len(raw),c['receipt_size_bytes'],'385size')
    text=r['text'];exact([s for s in text.splitlines() if s.startswith('PASS: ')],p['expected_ordered_PASS_labels385'],'all339ordered385labels')
    for marker in ['Result: PASS (339 passes, 0 failures)','step385_overlay_application_status\tPASS','step385_commit_scope_verification_status\tPASS',
                   '9 files changed, 10717 insertions(+)','[main d457428] '+c['exact_commit_message'],'061a0a0..d457428  main -> main']:
        exact(text.count(marker),1,'exact single385marker')
    exact(re.findall(r'^ create mode 100644 (.+)$',text,re.M),p['expected_created_paths385'],'exact385creates')
    head='d457428 (HEAD -> main, origin/main, origin/HEAD) '+c['exact_commit_message']
    exact(text.split('061a0a0..d457428  main -> main',1)[1].strip().splitlines(),[head,head,'promano@pc-arch ~/Descargas $'],'reportedcleanmatchingheads')
    return True
def validate_baseline(blobs,addition,p):
    validate_policy(p);exact(sorted(blobs),sorted(p['baseline_sha256']),'all2009predecessorpaths')
    exact(sha(addition),p['changelog_addition_sha256'],'exact386prefix')
    for rel,digest in p['baseline_sha256'].items():
        raw=blobs[rel]
        if rel=='CHANGELOG.md':
            if not raw.startswith(addition):raise ValueError('additive386prefix')
            raw=raw[len(addition):]
        exact(sha(raw),digest,'whole accepted385bytes '+rel)
    return True
def validate_inputs(inputs,sources,readme,p):
    validate_policy(p);exact(sorted(inputs),sorted(p['whole_input_paths']),'whole original input set')
    for key,raw in inputs.items():
        exact(sha(raw),p['whole_input_sha256'][key],'wholebyte '+key)
        exact(canonical(json.loads(raw)),p['whole_input_canonical_sha256'][key],'wholecanonical '+key)
    f=json.loads(inputs['freeze378']);exact(sorted(sources),sorted(r['path'] for r in f['review_sources']),'four inert roots')
    for row in f['review_sources']:exact(sha(sources[row['path']]),row['sha256'],'inertsource '+row['path'])
    exact(sha(readme),p['baseline_sha256']['README.md'],'exact README')
    return True
def validate_dossier(d,s,inputs,p):
    validate_policy(p);exact(canonical(d),p['dossier_canonical_sha256'],'whole integrated bounded feasibility dossier')
    exact(canonical(s),p['sources_canonical_sha256'],'primary register')
    f=json.loads(inputs['freeze378']);plan=json.loads(inputs['plan379'])
    exact(d['boundaries'],p['boundaries'],'closed native gates')
    rows=[]
    for n in range(380,386):
        original=json.loads(inputs['accepted'+str(n)+'dossier'])
        exact(len(original['candidates']),p['source_candidate_counts'][str(n)],'whole source candidate count')
        for index,row in enumerate(original['candidates']):rows.append((n,index,row))
    exact(len(d['candidates']),len(rows),'all45 source candidates')
    for merged,(n,index,row) in zip(d['candidates'],rows):
        exact(merged['source_step'],n,'source step');exact(merged['source_candidate_index'],index,'source index')
        exact(merged['whole_original_candidate'],row,'whole original candidate')
        exact(merged['disposition'],row['disposition'],'unchanged bounded verdict')
        exact(merged['candidate_specific_unsatisfied_obligation'],row['candidate_specific_unsatisfied_obligation'],'unchanged candidate reason')
    counts={kind:sum(row['disposition']==kind for row in d['candidates']) for kind in d['classification_taxonomy']}
    exact(d['bounded_candidate_verdict_counts'],counts,'derived verdict counts no scope discharge')
    exact([row['original_conflict'] for row in d['cross_conflict_review']],f['full_accepted377_unresolved_conflict_review'],'whole eight conflicts')
    exact([row['whole_original_blocker'] for row in d['full_blocker_review']],f['inherited372_feasibility_blockers'],'whole ten blockers')
    for suffix in ['future_test_entry_prerequisites','future_operational_readiness_prerequisites']:
        exact(d['whole377_'+suffix],f['full_accepted377_'+suffix],'whole original prerequisites')
    original316=json.loads(inputs['publication_requirements316'])
    exact(d['original316_whole_stage12'],next(r for r in original316['immutable_design_facts']['stages'] if r['index']==12),'whole original stage12')
    exact([c['id'] for c in d['candidates']],p['candidate_ids'],'all45 candidate identities')
    exact(plan['pause_policy']['original_condition_ids'],p['original_pause_condition_ids'],'nine original conditions')
    return True
def review(d,s,c,r,inputs,sources,readme,p):
    validate_acceptance(c,r,p);validate_inputs(inputs,sources,readme,p);validate_dossier(d,s,inputs,p)
    return json.loads(json.dumps({'step':386,'state':'repository-review-valid-user-acceptance-pending','dossier':d,
         'native_entry_blocked':True,'strong_safe_pause':False,'whole_input_bindings':p['whole_input_sha256'],
         'accepted_predecessor_commit_prefix':'d457428','full_commit_id_known':False}))
