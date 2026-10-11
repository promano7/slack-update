#!/usr/bin/env python3
"""Review supplied whole source/backend/independent oracle decisions only; no native operations."""
import hashlib
import json
import re
POLICY_SHA='756a4b3e1531fa6a97e5efea3b0555fd59ce773f51655b857edcdfd0c3d99ed9'
def sha(raw):return hashlib.sha256(raw).hexdigest()
def canonical(v):return sha(json.dumps(v,sort_keys=True,separators=(',',':'),ensure_ascii=True).encode())
def exact(value,expected,label):
    if type(value) is not type(expected) or canonical(value)!=canonical(expected):raise ValueError(label)
    return True
def validate_policy(p):return exact(canonical(p),POLICY_SHA,'authored385policy substitution')
def validate_acceptance(c,r,p):
    validate_policy(p);exact(canonical(c),p['confirmation_canonical_sha256'],'complete384confirmation')
    exact(canonical(r),p['receipt_canonical_sha256'],'complete uploaded384receipt')
    raw=r['text'].encode('utf-8');exact(sha(raw),c['receipt_sha256'],'unchanged384uploadedbytes');exact(len(raw),c['receipt_size_bytes'],'384size')
    text=r['text'];exact([s for s in text.splitlines() if s.startswith('PASS: ')],p['expected_ordered_PASS_labels384'],'all283ordered384labels')
    for marker in ['Result: PASS (283 passes, 0 failures)','step384_overlay_application_status\tPASS','step384_commit_scope_verification_status\tPASS',
                   '9 files changed, 4704 insertions(+)','[main 061a0a0] '+c['exact_commit_message'],'45f463f..061a0a0  main -> main']:
        exact(text.count(marker),1,'exact single384marker')
    exact(re.findall(r'^ create mode 100644 (.+)$',text,re.M),p['expected_created_paths384'],'exact384creates')
    head='061a0a0 (HEAD -> main, origin/main, origin/HEAD) '+c['exact_commit_message']
    exact(text.split('45f463f..061a0a0  main -> main',1)[1].strip().splitlines(),[head,head,'promano@pc-arch ~/Descargas $'],'reportedcleanmatchingheads')
    return True
def validate_baseline(blobs,addition,p):
    validate_policy(p);exact(sorted(blobs),sorted(p['baseline_sha256']),'all2001predecessorpaths')
    exact(sha(addition),p['changelog_addition_sha256'],'exact385prefix')
    for rel,digest in p['baseline_sha256'].items():
        raw=blobs[rel]
        if rel=='CHANGELOG.md':
            if not raw.startswith(addition):raise ValueError('additive385prefix')
            raw=raw[len(addition):]
        exact(sha(raw),digest,'whole accepted384bytes '+rel)
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
    validate_policy(p);exact(canonical(d),p['dossier_canonical_sha256'],'whole source backend independent oracle dossier')
    exact(canonical(s),p['sources_canonical_sha256'],'primary register')
    f=json.loads(inputs['freeze378']);plan=json.loads(inputs['plan379'])
    exact(d['boundaries'],p['boundaries'],'closed native gates')
    for number,keys in p['original_contract_keys'].items():
        original=f['full_original_contracts320_327'][number]['document']
        for key in keys:exact(d['original'+number+'_'+key],original[key],'whole'+number+' '+key)
    original316=json.loads(inputs['publication_requirements316'])
    exact(d['original316_whole_stage12'],next(r for r in original316['immutable_design_facts']['stages'] if r['index']==12),'whole original stage12')
    for number in ['375','376']:
        original=json.loads(inputs['design'+number])
        for key in p['original'+number+'_review_keys']:exact(d['original'+number+'_'+key],original[key],'whole'+number+' '+key)
    exact(d['original377_whole_entry_backend_conflict'],f['full_accepted377_unresolved_conflict_review'][3],'whole377 entry backend conflict')
    exact(d['original377_independent_two_platform_oracle_conflict'],f['full_accepted377_unresolved_conflict_review'][7],'whole377 independent oracle conflict')
    exact(d['original372_checked_graph_blocker'],next(r for r in f['inherited372_feasibility_blockers'] if r['family_id']=='checked-code-and-backend-graph'),'whole372 graph blocker')
    exact(d['original351_whole_expectation_contract'],json.loads(inputs['independent_expectation351']),'whole original351 expectation contract')
    original375=json.loads(inputs['design375'])
    exact(d['original335_independence_contract'],original375['full_original_independence_contract335'],'whole original335 independence')
    exact(len(d['original375_case_evidence_review']),52,'all original cases')
    exact(len(d['original325_reference_census']['functions']),166,'all static census rows')
    exact(len(d['original325_catalogue_nodes']),30,'all original designed domains')
    exact([c['id'] for c in d['candidates']],p['candidate_ids'],'eight candidate identities')
    exact([r['id'] for r in d['adversarial_schedules']],p['schedule_ids'],'fourteen conditional schedules')
    exact(plan['pause_policy']['original_condition_ids'],p['original_pause_condition_ids'],'nine original conditions')
    return True
def review(d,s,c,r,inputs,sources,readme,p):
    validate_acceptance(c,r,p);validate_inputs(inputs,sources,readme,p);validate_dossier(d,s,inputs,p)
    return json.loads(json.dumps({'step':385,'state':'repository-review-valid-user-acceptance-pending','dossier':d,
         'native_entry_blocked':True,'strong_safe_pause':False,'whole_input_bindings':p['whole_input_sha256'],
         'accepted_predecessor_commit_prefix':'061a0a0','full_commit_id_known':False}))
